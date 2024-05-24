 
-- -------------------------------------------------ANALYTICS 1-----------------------------------------------------------------------------------
DROP TABLE IF EXISTS consiglidintervento;
CREATE TABLE consiglidintervento (
`IDedificio` INT,
`idVano` INT, 
`ultimadata` DATE,
`postcalamita` INT,
`nopostcalamita` INT,
`probabilita` INT,
`tipologia` VARCHAR(45),
`spesa_necessaria` INT,
`priorita` INT
)
ENGINE = INnoDB;

DROP PROCEDURE IF EXISTS analytics1;
delimiter $$
CREATE PROCEDURE analytics1()
BEGIN 
TRUNCATE TABLE consiglidintervento;
INSERT INTO consiglidintervento
WITH allarme AS (SELECT seriale, idedificio,idPiano,idVano,timestamp,stimato,allarme,riparazprev,valore
				 FROM rilevamentoa
									UNION
				 SELECT seriale, idedificio,idPiano,idVano,timestamp,stimato,allarme,riparazprev,valore
				 FROM rilevamentob
									UNION
				 SELECT seriale, idedificio,idPiano,idVano,timestamp,stimato,allarme,riparazprev,valore
				 FROM rilevamentop
								    UNION
				 SELECT seriale, idedificio,idPiano,idVano,timestamp,stimato,allarme,riparazprev,valore
				 FROM rilevamentopo
									UNION
				 SELECT seriale, idedificio,idPiano,idVano,timestamp,stimato,allarme,riparazprev,valore
				 FROM rilevamentot
									UNION
				 SELECT seriale, idedificio,idPiano,idVano,timestamp,stimato,allarme,riparazprev,valore
				 FROM rilevamentog),
                 
partial1 AS( SELECT a.idvano,a.IDedificio, a.seriale, a.timestamp ,a.riparazprev, IF((c.livello IS NOT NULL),(10-c.livello), NULL) AS postcalamita, ((10-a.valore)*7) AS nopostcalamita    -- imposto dei valori che mi fanno capire quanto io sia vicino al danno
			 FROM allarme a LEFT OUTER JOIN colpo c ON a.timestamp=c.timestamp AND a.IDedificio=c.IDedificio),
             
partial2 AS( SELECT  idvano,IDedificio,seriale,riparazprev, LAST_VALUE(timestamp) OVER (PARTITION by seriale ORDER BY timestamp ) AS ultimadata, sum(postcalamita)%10  AS postcalamita     -- modulo10 ovvero ogni volta si raggiunge 10 il danno si concretizza     
			 FROM partial1                                                                 											   -- per questo sommo tutti i postcalamita insieme e ci faccio il mod
			 GROUP BY seriale,riparazprev),
             
partial3 AS( SELECT  idvano,IDedificio, seriale,riparazprev, LAST_VALUE(timestamp) OVER (PARTITION by seriale ORDER BY timestamp ) AS ultimadata, sum(nopostcalamita)%10  AS nopostcalamita  
			 FROM partial1
			 GROUP BY seriale,riparazprev),
             
partial4 AS( SELECT*
			 FROM partial2 NATURAL JOIN partial3), -- unisco idue indici che mi sono calcolato
             
area1 AS (SELECT*
		  FROM allarme NATURAL JOIN smartbuilding),
          
area2 AS (SELECT*
		  FROM area1 NATURAL JOIN areageografica),  -- cosi ottengo tutti i dati della tre tabelle
          
tot AS (SELECT count(*) AS totale, idarea
		FROM colpo NATURAL JOIN smartbuilding
		GROUP BY  idArea),
        
prob AS (SELECT (count(*)*100)/totale AS prob, idcalamita, idarea
		 FROM colpo NATURAL JOIN smartbuilding NATURAL JOIN tot
		 GROUP BY idCalamita, idArea),
         
area3 AS (SELECT idcalamita, seriale,prob  		 			-- calamita, idRilevatore, data, (coeffrischio*100)/rischiotot
		  FROM area2 NATURAL JOIN prob  
		  GROUP BY idcalamita, seriale, prob), 			  	-- coeeffrischio :rischiotot= x :100 ----> (coeffrischio*100)/rischiotot
          
parte123fuse AS (SELECT*
				 FROM partial4 NATURAL JOIN area3),
                 
costo1 AS ( SELECT idlavoro,tipologia,sum((orafINe-oraINizio)*stipENDioadora) AS costoa 
			FROM turno NATURAL JOIN lavoratore NATURAL JOIN lavoro
			WHERE tipologia IN(SELECT riparazprev FROM allarme)
			GROUP BY tipologia, idlavoro),
            
costo2 AS ( SELECT idlavoro,tipologia,sum(costotot) AS costob 
			FROM ordINe NATURAL JOIN lavoro
			GROUP BY tipologia, idlavoro),
            
costofINale AS (SELECT tipologia, AVG(costoa+costob) AS spesa_necessaria -- + % in base a livello
				FROM costo1 NATURAL JOIN costo2
				GROUP BY tipologia),
                
tuttofuso AS (SELECT*
			  FROM parte123fuse INner joIN costofINale ON riparazprev=tipologia)
              
SELECT idedificio, idvano, ultimadata, postcalamita, nopostcalamita, prob AS probabilita, tipologia, spesa_necessaria, rank() OVER(ORDER BY prob desc) AS priorita
FROM tuttofuso
GROUP BY idedificio, idvano, tipologia;

END$$
delimiter ;

CALL analytics1;

SELECT * 
FROM consiglidintervento;

-- --------------------------------------------------ANALYTICS 2-------------------------------------------------------------------------------

DROP TABLE IF EXISTS previsionedanni;
CREATE TABLE previsionedanni (
`IDedificio` INT,
`valore_minimo` INT, 
`valore_massimo` INT, 
`soglia_rimASta` INT, 
`ultima_data` DATE,
`data_minima` DATE,
`data_massima` DATE,
`priorita` INT,
`stato` VARCHAR(100)
)
ENGINE = INnoDB;

DROP PROCEDURE IF EXISTS analytics2;
delimiter $$
CREATE PROCEDURE analytics2()
BEGIN 
TRUNCATE TABLE previsionedanni;
INSERT INTO previsionedanni
WITH 
partial0 AS (SELECT *, LEAD(timestamp) OVER(PARTITION by idedificio ORDER BY timestamp) AS datadopo
			 FROM rilevamentog 
			 WHERE allarme=1 AND stimato=0),
             
partial01 AS (SELECT *, (((year(datadopo)*365 + mONth(datadopo)*30)+day(datadopo)-(year(timestamp)*365 + mONth(timestamp)*30)+day(timestamp))) AS intervalli
			  FROM partial0),
              
partial1 AS (SELECT idedificio, AVG(intervalli) AS intervalli, FIRST_VALUE(timestamp) OVER( PARTITION by idedificio ORDER BY timestamp ) AS prima_data, 
			 LAST_VALUE(timestamp) OVER( PARTITION by idedificio ORDER BY timestamp ) AS ultima_data,  
			  sum(valore) AS sommadeivalori, count(*) AS avvenimenti, max(valore) AS maxv, min(valore) AS minv
             FROM partial01 
             GROUP BY idedificio),

partial2 AS (SELECT idedificio, intervalli, avvenimenti, (maxv-minv)/avvenimenti AS variabilitavalori, sommadeivalori, minv, maxv, ultima_data, prima_data
			 FROM partial1),

partial3 AS(SELECT *, IF(100-sommadeivalori<0,0,100-sommadeivalori) AS sogliarimasta  
			FROM partial2),
            
partial4 AS (SELECT *, sogliarimasta/minv AS quanti_intervalli_minimi, sogliarimasta/maxv AS quanti_intervalli_massimi
			 FROM partial3),
             
partial5 AS (SELECT *, quanti_intervalli_minimi*intervalli AS periodorimanentemax, quanti_intervalli_massimi*intervalli AS periodorimanentemin
			 FROM partial4),
             
partial6 AS (SELECT*, ultima_data + INterval periodorimanentemin day AS dataminima, ultima_data + INterval periodorimanentemax day AS datamassima
			 FROM partial5)
             
SELECT idedificio, minv, maxv, sogliarimasta, ultima_data, dataminima, datamassima,rank() OVER (ORDER BY sogliarimasta, dataminima)AS  priorita,
			IF(sogliarimasta>=60,'danni lievi/trascurabili', 
            IF(sogliarimasta<60 AND sogliarimasta>=30,'danni da considerare', 
            IF(sogliarimasta<30 AND sogliarimasta>=1,'intervenire quanto prima','richiesto intervento immediato'))) AS stato
FROM partial6;
END$$
delimiter ;

CALL analytics2;

SELECT * 
FROM previsionedanni;

-- SPIEGAZIONE SOMMARIA
-- ogni edificio abbiamo una somma dei valori , 100-sommadei valori e troviamo la soglia IN cui scatta il danno,
--  e l ANDamento cON cui si fa la stima è intervallo che manca per arrivare a 100 diviso il valore minio o massimo  
-- e si trova quanti 'clock' mancano che poi ANDiamo a moltiplicare per lintervallo dei giorni
