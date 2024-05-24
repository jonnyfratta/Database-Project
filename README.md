
# Smart Buildings: a database for construction companies

This project was realized for the "Basi di Dati" course at my bachelor's degree in Computer Engineering. The assignment was to create a database used by an imaginary construction company who has constructed and is constructing different buildings.


## Installation and Run Locally
1. Clone the repository:
    ```sh
    git clone https://github.com/jonnyfratta/Database-Project.git
    ```

2. Install MySQL Workbench:
    - for the Windows users, you can download it directly from here:
      ```link
      https://dev.mysql.com/downloads/installer/
      ```
    - for MacOs and Linux users, you need to download MySQL Community Server from the first link and then the MySQL Workbench from the second one:
      ```link
      https://dev.mysql.com/downloads/mysql/
      https://dev.mysql.com/downloads/workbench/
      ```
     
3. Launch MySQL Workbench, create a connection to the MySQL server (user: root; password: "chosen during installation"; host: 127.0.0.1; port: 3306).

4. Open the connection you just created, go to file and click 'Open Script' and then open and execute (yellow lightning icon) one by one the following files in this very order:
    1. 1_Script_e_Trigger.sql
    2. 2_Popolamento.sql

7. Enjoy
    
## Usage/Examples
We were asked to come up with eight operations that could be made on the database and to evaluate effiency through them. You can find them in the "3_Operazioni" file but you can one could make more of course.

Furthermore we were asked to developed two more complex and more intensive operations contained in the 4_Analytics


## Development

We develped this project in multiple phases:

### Phase 1: ER
In the first phase we created the ER-Diagrams to have a scheme of the final product. You can find both the first version and the restructured one under the names "NonRistrutturato.pdf" and "Ristrutturato.pdf"

### Phase 2: Crow's foot scheme
In order to convert the ER-diagram to SQL code what we did was recreate the ER direclty on Workbench, using the Crow's foot notation and then converting it to code.

### Phase 3: Population
We populated the database with example data and did not follow the Volumes written in the documentation, since it was just for simulation purposes

### Phase 4: Operations and Analytics
You can find a detailed explaination with Images in the documentation under the name "Documentazione".

### Final Phase: Evaluations
Finally we evaluated the efficiency of our work and how much stress it can sustain.


## Optimizations

An optimization we realized during the exam it could be applied, is to remove the redundant external keys used in the following Entities:
- StadioAvanzamento
- Lavoro
- Turno
- Oridne
- Colpo
- Piano
- Vano
- RilevamentoA
- RilevamentoB
- RilevamentoP
- RilevamentoPO
- RilevamentoT
- RilevamentoG

## Documentation

[Documentation](https://github.com/jonnyfratta/Database-Project/blob/master/Documentazione.pdf)


## Authors

- [@jonnyfratta](https://www.github.com/jonnyfratta)
- [@msegreto](https://www.github.com/msegreto)

