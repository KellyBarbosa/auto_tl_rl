# Auto_TL_RL

## Developers

> Gleice Kelly Barbosa Souza <br> _Robotics and Artificial Intelligence (RAI)_ <br> _Universidade Federal do Recôncavo da Bahia (UFRB)_
>
> [Currículo Lattes](http://lattes.cnpq.br/7270522970235184) | [E-mail](kelly.189@hotmail.com) | [ORCID](https://orcid.org/0009-0001-3679-3298)

> André Luiz Carvalho Ottoni <br> _Robotics and Artificial Intelligence (RAI)_ <br> _Universidade Federal do Recôncavo da Bahia (UFRB)_
>
> [Currículo Lattes](http://lattes.cnpq.br/2003401420560517) | [E-mail](andre.ottoni@ufrb.edu.br) | [ORCID](https://orcid.org/0000-0003-2136-9870)

Algorithm described in article "Transfer Reinforcement Learning for Combinatorial Optimization Problems", submitted to MDPI.

## About Auto_TL_RL

Auto_TL_RL is an algorithm developed to automate transfer learning between two combinatorial optimization problems: the Asymmetric traveling salesman problem (ATSP) and the Sequential ordering problem (SOP). Additionally, the algorithm employs reinforcement learning to solve the aforementioned problems.

Using the SARSA (State – Action – Reward — State — Action) algorithm from reinforcement learning, Auto_TL_RL transfers the learning matrix from ATSP (source problem) to SOP (target problem). The transfer learning is fully automated, driven by automated machine learning.

Thus, Auto_TL_RL encompasses the following concepts:

- Automated Machine Learning (AutoML)
- Transfer Learning (TL)
- Reinforcement Learning (RL)

### Auto_TL_RL Workflow

<p align="center">
<img src="https://github.com/KellyBarbosa/auto_tl_rl/assets/40704890/f4a70c54-8172-4077-b361-0587c81d87f4" />  
</p>

### Technical Description of Auto_TL_RL

The algorithm operates based on the files `Auto_TL_RL.R` and `control.txt`. Additionally, the data for conducting experiments is located in the `data` folder.

The `control.txt` file has 4 columns:

- 1° column: Instance name;
- 2° column: Number of nodes in the instance;
- 3° column: Indicates whether there is already a learning matrix stored for the instance. The value 1 indicates that the matrix already exists, while the value 0 indicates that the matrix has not yet been created;
- 4° column: Name of the learning matrix file (matrices are stored in `data/matrices/`).
