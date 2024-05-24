-- VALUTAZIONE STATO EDIFICIO PER ANALYTICS
DROP TABLE IF EXISTS statodiedificio;
CREATE TABLE statodiedificio (
`IDedificio` INT,
`soglia_rimASta` INT, 
`priorita` INT,
`stato` VARCHAR(100)
)
ENGINE = InnoDB;

DROP PROCEDURE IF EXISTS statoedificio;
DELIMITER $$
CREATE PROCEDURE statoedificio()
BEGIN
TRUNCATE TABLE statodiedificio;
INSERT INTO statodiedificio
WITH 
partial0 AS (SELECT seriale,idedificio, timestamp,valore, LEAD(timestamp) OVER(partition by idEdificio ORDER BY timestamp) AS datadopo
			 FROM rilevamentoa 
			 WHERE allarme=1 AND stimato=0
						UNION
			 SELECT seriale,idedificio, timestamp,valore, LEAD(timestamp) OVER(partition by idEdificio ORDER BY timestamp) AS datadopo
			 FROM rilevamentob 
			 WHERE allarme=1 AND stimato=0
						UNION
			 SELECT seriale,idedificio, timestamp,valore, LEAD(timestamp) OVER(partition by idEdificio ORDER BY timestamp) AS datadopo
			 FROM rilevamentog 
			 WHERE allarme=1 AND stimato=0
						UNION
			 SELECT seriale,idedificio, timestamp,valore, LEAD(timestamp) OVER(partition by idEdificio ORDER BY timestamp) AS datadopo
			 FROM rilevamentop 
			 WHERE allarme=1 AND stimato=0
					    UNION
			 SELECT seriale,idedificio, timestamp,valore, LEAD(timestamp) OVER(partition by idEdificio ORDER BY timestamp) AS datadopo
			 FROM rilevamentopo
			 WHERE allarme=1 AND stimato=0
						UNION
			 SELECT seriale,idedificio, timestamp,valore, LEAD(timestamp) OVER(partition by idEdificio ORDER BY timestamp) AS datadopo
			 FROM rilevamentot 
			 WHERE allarme=1 AND stimato=0),
             
partial1 AS (SELECT idedificio,sum(valore)%100 AS sommadeivalori
			 FROM partial0 
			 group by idEdificio),
             
partial2 AS (SELECT idedificio, sommadeivalori
			 FROM partial1),
             
partial3 AS(SELECT *, IF(100-sommadeivalori<0,0,100-sommadeivalori) AS sogliarimASta  
			FROM partial2)
            
SELECT idedificio, sogliarimASta,RANK() OVER (ORDER BY sogliarimASta)AS  priorita, IF(sogliarimASta>=60,'danni lievi/trAScurabili',
		IF(sogliarimASta<60 AND sogliarimASta>=30,'danni da considerare',
			IF(sogliarimASta<30 AND sogliarimASta>=5,'intervenire quanto prima','richiesto intervento immediato'))) AS stato
FROM partial3;
END $$
DELIMITER ;

CALL statoedificio;
SELECT *
FROM statodiedificio;



-- OPERAZIONE 1
/*
DROP TRIGGER IF EXISTS costo_pedil;
DELIMITER $$
CREATE TRIGGER costo_pedil
AFTER INSERT ON stadioavanzamento
FOR EACH ROW
BEGIN
        
	call COSTOTOT_(NEW.codprogetto);
 
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS COSTOTOT_;
DELIMITER $$
CREATE PROCEDURE COSTOTOT_(in codprog varchar(45))
begin
	declare _costo_ integer default 0;
    DECLARE perc INTEGER DEFAULT 0;
	SET _costo_ = (
		SELECT SUM(costo)
		FROM stadioavanzamento
		WHERE CodProgetto=codProg);
	
    UPDATE progettoedilizio
		set costotot=_costo_
        where codprogetto=codprog;
        
	SET perc=
		(
        with
			cont as(
				select codprogetto , count(*)as c
				from stadioavanzamento
				group by codprogetto
					)
			select c*100/numstadi
            from progettoedilizio natural join cont
            where codprogetto=codprog
        );
	UPDATE progettoedilizio
	SET percentLAVORI = perc
	WHERE codprogetto=codprog;

end $$
delimiter ;
*/

-- OPERAZIONE 1

-- OPERAZIONE 2
-- 2. Numero di piani medio IN bASe al livello sicurezza edIFicio

DROP PROCEDURE IF EXISTS operazione2;
DELIMITER $$
CREATE PROCEDURE operazione2()
BEGIN

    WITH
    parziale AS( SELECT livellosicurezza,idedIFicio, count(idpiano) AS x
				 FROM smartbuildINg NATURAL JOIN piano
				 GROUP BY livellosicurezza,idedIFicio)
    SELECT livellosicurezza, avg(x)
    FROM parziale
    GROUP BY livellosicurezza
    ORDER BY livellosicurezza;
END $$
DELIMITER ;

-- OPERAZIONE 3 
-- 3. Calamità più rilevata per ogni Area Geografica

DROP PROCEDURE IF EXISTS operazione3;
DELIMITER $$
CREATE PROCEDURE operazione3( )
BEGIN
	
   WITH parziale AS(SELECT idarea, idcalamita, count(idcalamita) AS x
					FROM colpo NATURAL JOIN smartbuildINg
					GROUP BY idarea, idcalamita)
    SELECT idarea,ubicazione, idcalamita,Tipologia,x AS numero_eventi, rank() over( partition by idarea  ORDER BY x) AS classifica
    FROM parziale NATURAL JOIN areageografica NATURAL JOIN calamita;
END $$
DELIMITER ;

-- OPERAZIONE 4
-- 4. ranking dei Progetti Edilizi con il maggior numero di operai impiegati per Area Geografica

DROP PROCEDURE IF EXISTS operazione4;
DELIMITER $$
CREATE PROCEDURE operazione4( )
BEGIN
	WITH
    x AS (SELECT idarea, CodProgetto, count(distINct codfiscale) AS num_operai
		  FROM  progettoedilizio NATURAL JOIN turno NATURAL JOIN smartbuildINg
		  GROUP BY idarea, CodProgetto)
    SELECT idarea, CodProgetto, num_operai, rank() over ( partition by idarea ORDER BY num_operai DESC ) AS ranking
    FROM  x;
    
END $$
DELIMITER ;

-- OPERAZIONE 5
-- 5. Calcolo degli straordinari anno rispetto versione mensile tolta clausola WHERE e 
-- oresettimanamax diventano ore annuali senno il risultato non ha senso

DROP PROCEDURE IF EXISTS operazione5;
DELIMITER $$
CREATE PROCEDURE operazione5()
BEGIN
	WITH x AS (SELECT CodFiscale, IF( (sum(hour(t1.orafINe)-hour(t1.oraINizio))-(l.MaxOreAnnuali) > 0), (sum(hour(t1.orafINe)-hour(t1.oraINizio))-(l.MaxOreAnnuali)), 0) AS straordinari
			   FROM turno t1 NATURAL JOIN lavoratore l
			   GROUP BY L.Codfiscale)
    SELECT *,dense_rank() over (ORDER BY straordinari desc) AS classifica_stacanovisti
    FROM x;
END $$
DELIMITER ;

-- OPERAZIONE 6
-- 6. Visualizzazione della spesa totale effettuata dalla sua costruzione per tutti i lavori su quel
-- determINato smart buildINg
DROP PROCEDURE IF EXISTS operazione6;
DELIMITER $$
CREATE PROCEDURE operazione6( )
BEGIN

SELECT idedIFicio, sum(costotot) AS costo_complessivo_spese_edIFicio
FROM  progettoedilizio
GROUP BY idedIFicio;

END $$
DELIMITER ;
 
-- OPERAZIONE 7
-- 7. Ricavare il materiale più utilizzato per ogni tipologia di Lavoro()
DROP PROCEDURE IF EXISTS operazione7;
DELIMITER $$
CREATE PROCEDURE operazione7()
BEGIN
	WITH
	parziale AS (SELECT tipologia,nomemateriale,nomefornitore, sum(Quantita) AS x
				 FROM ordine i INNER JOIN lavoro l ON i.idlavoro=l.idlavoro
				 GROUP BY tipologia,nomemateriale,nomefornitore)
    SELECT tipologia,nomemateriale,nomefornitore
    FROM parziale
    GROUP BY tipologia
    HAVING max(x);
END $$
DELIMITER ;
 
-- OPERAZIONE 8
-- 8. Variazione coefficiente rischio totale di calamità rispetto al mese precedente

DROP PROCEDURE IF EXISTS operazione8;
DELIMITER $$
CREATE PROCEDURE operazione8( )
BEGIN
	WITH 
    parziale AS(SELECT r2.idarea, avg(r2.coeffrischio) AS meseprec
			    FROM rischio r2 
				WHERE month(r2.datarilevazione) <=(SELECT month(r.datarilevazione)-1 FROM rischioattuale r WHERE r.idcalamita=r2.idcalamita and r2.idarea=r.idarea)
				GROUP BY r2.idarea)
    SELECT a.idarea,a.ubicazione, (avg(a.RischioTot)-meseprec) AS variazione_coefficente
    FROM parziale p NATURAL JOIN areageografica a 
    GROUP BY a.idarea;

END $$
DELIMITER ;

-- CALL operazione1;
CALL operazione2;
CALL operazione3;
CALL operazione4;
CALL operazione5;
CALL operazione6;
CALL operazione7;
CALL operazione8;