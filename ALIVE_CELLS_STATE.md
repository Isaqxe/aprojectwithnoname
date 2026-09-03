# Alive Cells — Estado Atual do Projeto

> **Snapshot de recuperação da sessão.**
>
> Este arquivo registra o estado conhecido do projeto **Alive Cells** no momento em que esta sessão foi encerrada, para permitir continuidade em outra sessão sem depender da memória da conversa.
>
> **Repositório:** `Isaqxe/aprojectwithnoname`
>
> **Objetivo do projeto:** jogo/protótipo de ecossistema celular para a feira de ciências, com foco em **Genética e Hereditariedade**.
>
> **Estado geral:** o núcleo da simulação está funcional e a fase atual é de **polimento, balanceamento e consolidação do sistema NEO de genética**. A camada de Tools foi criada para experimentação controlada, mas ainda possui pontos de integração que podem ser refinados.

---

## 1. Visão geral da arquitetura

O projeto é uma simulação de organismos celulares em um laboratório experimental circular. O fluxo principal é aproximadamente:

`TestSimulation`
→ `CellManager` / `ResourceSpawner` / `ExperimentalDomain`
→ criação das células
→ `simulation_cell_clean.gd`
→ `simulation_cell_optimized.gd`
→ componentes de organismo (`cell.gd`, comportamento, mitose etc.)
→ `cell_genetics.gd`
→ `gene_data.gd` + `gene_formulas.gd`

Há uma separação deliberada entre:

- **simulação populacional**, coordenada por `CellManager`;
- **organismo individual**, representado pela célula de simulação e seus componentes;
- **genética**, concentrada no sistema NEO;
- **recursos/energia**, tratados por `Cell`, `WorldResource` e `WorldResourceSpawner`;
- **domínio ambiental**, concentrado em `ExperimentalDomain`;
- **observabilidade**, fornecida por `CellInspector` e pela telemetria/debug;
- **ferramentas de experimentação**, concentradas em `SimulationTools`.

A intenção arquitetural atual é que as Tools **orquestrem sistemas existentes**, e não passem a possuir a biologia. O documento de arquitetura das Tools define explicitamente essa direção e mantém NEO separado das ferramentas. `CellInspector` é a fonte oficial da seleção de célula. cite-placeholder

---

## 2. Sistemas principais

### 2.1 CellManager

Arquivo principal:

`GPT/CellSystem/cell_manager.gd`

Responsabilidades:

- registrar células vivas;
- criar células novas através do `CellFactory`;
- criar células derivadas de um progenitor;
- criar o jogador;
- controlar `initial_population` e `max_population`;
- opcionalmente executar auto-spawn;
- manter a associação célula → espécie;
- criar/registrar nomes e cores de espécies;
- registrar nascimentos e mortes;
- registrar mutações;
- manter estatísticas por espécie;
- manter população histórica e eventos recentes;
- acompanhar geração máxima;
- expor uma fotografia de telemetria da simulação.

O manager possui atualmente parâmetros de spawn como `auto_spawn`, `spawn_interval`, `initial_population`, `max_population` e `initial_species_count`. Ele também mantém `registered_cells`, `player_cell`, `known_species`, `species_colors` e contadores como `total_births`, `total_deaths`, `peak_population`, `highest_generation` e `total_mutations`. fileciteturn1085file0

A identidade genética é a fonte preferida da espécie. Quando uma célula é criada, o manager resolve uma espécie existente ou gera uma espécie aleatória, registra essa espécie e passa o identificador ao `CellFactory`. Células-filhas herdam o identificador da espécie do progenitor. fileciteturn1085file0

O manager também tem lógica de manutenção/streaming: resolução dos nós principais, limpeza de referências inválidas, atualização da área de simulação, atualização do processamento das células e aplicação dos limites do domínio. fileciteturn1085file0

### 2.2 CellFactory / criação de organismos

A criação de organismos passa pelo `CellFactory`, ao qual o `CellManager` delega a instanciação da cena da célula.

Existem dois fluxos principais:

1. **Célula nova:** recebe uma espécie e inicializa genética aleatória NEO.
2. **Célula filha:** recebe os dados hereditários do progenitor e inicializa genética herdada, seguida de mutação.

A reprodução por mitose continua sendo um processo da simulação/organismo, não uma responsabilidade de `gene_data.gd` nem de `gene_formulas.gd`.

### 2.3 simulation_cell_clean.gd

Arquivo base de organismo:

`GPT/CellSystem/simulation_cell_clean.gd`

Este é o caminho “limpo” que centraliza o comportamento estrutural da célula. Ele coordena identidade, genética, comportamento, ataque, percepção, mitose, aplicação do fenótipo ao organismo e integração com os componentes de célula.

O sistema ainda possui código histórico de combate, inclusive a noção antiga de `elimination_resource_reward`. Essa regra não é mais desejada como economia principal, e o caminho otimizado ativo zera essa recompensa explicitamente.

### 2.4 simulation_cell_optimized.gd

Arquivo ativo especializado:

`GPT/CellSystem/simulation_cell_optimized.gd`

A cena atual de célula usa este caminho otimizado.

Responsabilidades e otimizações atuais:

- percepção através de índices espaciais;
- busca de recursos através de índice espacial;
- comportamento com decisões em intervalos de aproximadamente `0.15 s` por padrão;
- decisões ligeiramente escalonadas/randomizadas para evitar que todas as células processem AI no mesmo instante;
- raio de percepção de recursos ampliado por fator `2.0` quando a célula está com fome;
- período de graça de aproximadamente `15 s` para células recém-criadas;
- sincronização da capacidade de energia com o custo de mitose;
- atualização do `CollisionShape2D` a partir do tamanho biológico da célula;
- registro de mutações já presentes na genética durante a criação/herança;
- limpeza do organismo após `cell_data.alive` passar a falso.

O arquivo também contém a correção de balanceamento que desativa a antiga recompensa fixa por eliminação:

`elimination_resource_reward = 0.0`

Assim, no caminho otimizado que efetivamente está sendo usado, mortes não geram mais um bônus fixo separado; a economia passa pelo drop da energia armazenada na própria célula. fileciteturn1081file0

O processamento de AI usa `CellSpatialIndexes` e `ResourceSpatialIndexes` quando disponíveis. Na ausência deles, há fallback para consulta global do grupo de células. fileciteturn1081file0

---

## 3. Sistema NEO de genética

Arquitetura genética atual:

`GPT/CellSystem/cell_genetics.gd`

A ideia central é separar claramente:

**gene → alelos → genótipo → fenótipo → característica biológica**

Reprodução continua fora da camada genética.

O sistema atualmente divide genes em três blocos principais:

### 3.1 Attribute genes

Genes numéricos contínuos:

- `health`
- `damage`
- `speed`
- `size`
- `regeneration_rate`
- `efficiency`

Cada gene de atributo não é uma simples lista de valores possíveis. Ele é representado por **duas haplotipos de 4 a 6 loci binários**.

Exemplo conceitual:

- haplótipo A = `ABCD`
- haplótipo B = `ABCD`
- genótipo combinado = `AABBCCDD`

Uma mutação de um único locus pode produzir, por exemplo:

`AABBCCDD`

→

`AaBBCCDD`

Ou seja, apenas uma posição mudou.

Esse é um dos princípios mais importantes do NEO atual: os atributos possuem uma estrutura genética composta, em vez de serem apenas números aleatórios. fileciteturn1075file0

Faixas atuais dos atributos:

- `health`: **40–120**
- `damage`: **5–25**
- `speed`: **45–100**
- `size`: **10–24**
- `regeneration_rate`: **2–6**
- `efficiency`: **0–1**

Esses limites estão declarados em `cell_genetics.gd`. fileciteturn1075file0

### 3.2 Adaptation genes

Genes ambientais contínuos, atualmente:

- `cold_adaptation`
- `temperate_adaptation`
- `heat_adaptation`
- `void_adaptation`
- `humidity_adaptation`

Atualmente os genes de adaptação são armazenados como valores normalizados entre aproximadamente `0.25` e `0.75` na inicialização aleatória.

Importante: o formato existe e o inspetor mostra alguns desses valores, mas nem todo gene de adaptação possui ainda uma consequência biológica forte aplicada no gameplay.

### 3.3 Characteristic genes

Genes verdadeiramente binários de presença/ausência:

- `territorial`
- `cooperative_hunter`
- `camouflage`
- `armor`
- `toxin`
- `specialized_feeding`

Esses genes representam características, e não uma escala de potência.

Para um gene binário:

- `0 + 0` → ausente;
- `0 + 1` → presente;
- `1 + 1` → presente.

O modo de expressão correspondente é `presence`. fileciteturn1076file0

### 3.4 Behavior genes

Há também genes numéricos relacionados ao comportamento:

- `sociality`
- `aggression`
- `caution`
- `group_response`

No estado atual, eles ficam sob a categoria `characteristic`, apesar de conceitualmente representarem comportamento. A intenção registrada anteriormente era evitar criar uma categoria genética nova apenas para isso.

---

## 4. GeneData

Arquivo:

`GPT/CellSystem/gene_data.gd`

`GeneData` é um `RefCounted` leve que representa **uma unidade genética**.

Campos principais:

- `name`
- `category`
- `allele_a`
- `allele_b`
- `expression_mode`
- `contribution_table`

Categorias atuais:

- `attribute`
- `adaptation`
- `characteristic`

Modos de expressão atualmente definidos:

- `mean`
- `presence`
- `attribute_sequence`
- `dominant`
- `recessive`
- `codominant`

Nem todos os modos estão sendo usados com a mesma intensidade ainda.

`GeneData` fornece:

- `genotype()` para devolver os dois alelos;
- `combined_genotype()` para genes de sequência de atributo;
- `expressed_value()`;
- `phenotype()`;
- `to_dictionary()`;
- `from_dictionary()`.

Um detalhe arquitetural importante foi corrigido: quando uma célula filha recebe genes herdados, `cell_genetics.gd` serializa e reconstrói os objetos `RefCounted`, de modo que progenitor e filho **não compartilhem o mesmo objeto mutável de genética**. fileciteturn1076file0

---

## 5. GeneFormulas

Arquivo:

`GPT/CellSystem/gene_formulas.gd`

Esta é a camada matemática do NEO.

Ela não faz hereditariedade; apenas calcula expressão genética.

Principais funções conceituais:

### `evaluate`

Seleciona o método de expressão:

- `presence` → OR lógico entre os dois alelos;
- `attribute_sequence` → soma as contribuições dos loci;
- demais casos → média dos dois alelos.

### `genotype`

Retorna `[allele_a, allele_b]`.

### `combined_sequence`

Intercala locus por locus:

`ABCD` + `abcd`

→ `AaBbCcDd`

### Contagem de loci

Há um cache de quantidade de loci por nome de gene.

A arquitetura escolhe **uma quantidade estável por gene durante a simulação**, entre 4 e 6 loci. Isso significa que células diferentes usam a mesma “alfabeto genético” estrutural para o mesmo atributo. fileciteturn1077file0

### Tabelas de contribuição

Cada gene de atributo possui uma tabela de contribuição aleatória compartilhada pela simulação.

A tabela é gerada uma vez por gene e normalizada para que os extremos teóricos do gene coincidam com a faixa desejada.

Isso evita ter de escrever manualmente uma tabela fixa de contribuições para cada atributo. fileciteturn1077file0

### Expressão de atributo

O fenótipo de um atributo por sequência é obtido somando as contribuições de todos os alelos em todos os loci.

---

## 6. Mutação

Configuração atual da genética:

- `mutation_chance = 0.10`
- `mutation_strength = 0.05`

Ou seja, a chance padrão de um gene sofrer mutação em uma passagem é `10%`.

Para genes de sequência de atributos:

- escolhe-se um locus em uma das duas haplotipos;
- o símbolo `A` vira `a` ou `a` vira `A`;
- apenas aquela posição é alterada.

Para genes binários:

- um dos dois alelos é escolhido;
- seu valor lógico é invertido.

Para genes numéricos:

- os alelos sofrem pequena variação multiplicativa baseada em `mutation_strength`;
- genes normalizados são limitados a `[0,1]`.

`last_mutation_count` é mantido na genética para permitir que outras camadas contabilizem as mutações ocorridas. fileciteturn1075file0

### Observação importante de estado

Os genes numéricos de adaptação e comportamento atualmente começam com **o mesmo valor nos dois alelos**. Isso foi observado como uma imperfeição de representação e poderá ser revisado numa etapa futura. Não foi tratado como prioridade nesta sessão.

Da mesma forma, ainda existe diferença entre a mutação de genes de atributo e a mutação dos genes numéricos não-atributo. Não mexer nisso durante o balanceamento sem uma decisão explícita, porque já existe gameplay funcional em cima do sistema atual.

---

## 7. Aplicação genética → biologia

A célula de simulação usa o fenótipo NEO para preencher a biologia real do organismo.

A intenção atual é:

- `health` → vida máxima;
- `damage` → dano de ataque;
- `speed` → velocidade;
- `size` → tamanho físico/visual e influência energética;
- `regeneration_rate` → regeneração;
- demais genes → características/comportamento/ambiente conforme forem suportados.

`simulation_cell_optimized.gd` explicitamente chama o caminho de aplicação do fenótipo e ignora os valores antigos de biologia quando o NEO já está disponível. fileciteturn1081file0

### Eficiência

`efficiency` já existe como gene de atributo e produz fenótipo em `[0,1]`, mas **ainda não está plenamente aplicado à economia energética do organismo**.

Isso é um dos candidatos mais naturais para a próxima etapa de balanceamento NEO.

---

## 8. Cell / metabolismo e energia

Arquivo:

`GPT/CellSystem/cell.gd`

Este componente guarda a fisiologia básica e os recursos energéticos da célula.

Valores padrão atuais:

- capacidade de recursos: **500**;
- energia inicial: **35% da capacidade**;
- gasto base: **0.70/s**;
- gasto por movimento: **0.30/s**, modulado por velocidade e atividade;
- custo por tamanho: **0.008 × size**;
- limiar de fome: **45%**;
- limiar de starvation: **20%**;
- limiar crítico: **5%**;
- dano de fome crítica: **3/s**;
- cura ao voltar a receber alimento estando em estado crítico: **12**.

O metabolismo combina:

`base + custo de tamanho + custo de movimento`

A velocidade é usada para normalizar o custo de movimento com relação a um fator de referência de `75`.

A célula possui estados:

- `SATIATED`
- `HUNGRY`
- `STARVING`
- `CRITICAL`

Quando a energia cai muito, a regeneração também é reduzida. Em energia crítica a regeneração é desligada. fileciteturn1078file0

A célula aceita recursos até sua capacidade e possui funções para:

- `add_resources()`;
- `consume_resources()`;
- `collect` indiretamente através do recurso do mundo;
- regenerar;
- receber dano;
- atacar;
- morrer.

---

## 9. Nova economia de morte: energia armazenada vira recurso

Esta foi a alteração de balanceamento mais recente e deve ser tratada como **a regra econômica atual**.

Antes havia uma pequena recompensa fixa associada à eliminação de uma célula.

Agora:

> **quando uma célula morre, toda a energia que ela ainda possui é convertida em recursos do mundo.**

O fluxo de morte em `cell.gd` é:

1. ler `resources` da célula;
2. procurar um `ResourceSpawner` no grupo `ResourceSpawners`;
3. chamar `spawn_death_drop(global_position, stored_energy)`;
4. zerar os recursos da célula para impedir duplicação;
5. marcar `alive = false`;
6. zerar a vida.

Assim, a morte cria uma conversão explícita:

`energia armazenada do organismo`
→ `recursos do mundo`

Isso fecha melhor o ciclo energético do ecossistema. fileciteturn1078file0

---

## 10. WorldResource

Arquivo:

`GPT/CellSystem/world_resource.gd`

É o item de comida/energia coletável.

Valores padrão:

- `amount = 25`
- `radius = 6`

O recurso:

- pertence ao grupo `WorldResources`;
- pode ser coletado uma única vez;
- ao ser coletado, devolve seu `amount`, zera a própria quantidade e é removido com `queue_free()`;
- usa uma representação visual extremamente barata de duas circunferências.

A redução recente das artes/efeitos caros para apenas dois `draw_circle()` foi importante para eliminar um gargalo de desempenho que estava causando lag. fileciteturn1080file0

---

## 11. WorldResourceSpawner

Arquivo:

`GPT/CellSystem/world_resource_spawner.gd`

Responsabilidades:

- spawn inicial de recursos;
- respawn gradual;
- controle de `initial_resources`;
- controle de `max_resources`;
- espaçamento mínimo de recursos **normais**;
- adaptação da quantidade do recurso à densidade alimentar do ambiente;
- transformação da energia das células mortas em piles de recursos.

Parâmetros atuais relevantes:

- `initial_resources = 140` por padrão do script, mas esse valor é sobrescrito por `SimulationConfig` quando presente;
- `max_resources = 500` por padrão do script, também sobrescrito pela configuração;
- `spawn_interval = 0.75`;
- `minimum_spacing = 28`;
- `max_spawn_attempts = 12`;
- `base_spawn_multiplier = 1.15`;
- multiplicador mínimo por food density: `0.75`;
- multiplicador máximo: `1.60`;
- respawn quando abaixo de `60%` do máximo;
- emergency spawn abaixo de `25%`, com intervalo de `0.30`.

O spawner encontra o ambiente no ponto escolhido e modifica a quantidade do recurso usando `food_density`. fileciteturn1079file0

### Death drops

Configuração atual:

- `death_drop_max_per_node = 1000`
- `death_drop_min_spacing = 28` (legado da primeira implementação; não é usado para impedir sobreposição das piles de morte)
- `death_drop_max_attempts = 12` (também mantido, embora a implementação atual não use o espaçamento para as piles)

Regra:

- primeira pile: no local da morte;
- máximo de `1000` de energia por node;
- caso haja mais de `1000`, o excedente é quebrado em outras piles;
- piles excedentes são distribuídas em posições aleatórias do domínio;
- a posição final é limitada ao domínio experimental;
- piles de morte **podem se sobrepor** a outros recursos/piles.

A decisão de permitir sobreposição foi deliberada para evitar que energia fosse silenciosamente perdida quando o espaço estivesse ocupado. O sistema preserva o valor total da energia em vez de rejeitar o drop por causa do espaçamento normal. fileciteturn1079file0

### Cuidado com max_resources

`max_resources` continua sendo, na lógica normal, um limite de **quantidade de nós**, não um limite direto de energia total.

As piles de morte atualmente bypassam esse limite. Isso preserva a energia, mas significa que um grande volume de mortes pode aumentar a quantidade de nodes de recurso acima do teto normal.

Isso é aceitável para a fase atual de balanceamento, mas deve ser monitorado por desempenho.

---

## 12. ExperimentalDomain

O domínio experimental atual não é mais o sistema procedural complexo abandonado anteriormente.

A direção atual é um **laboratório circular/predefinido**, com raio configurável.

Funções importantes usadas pelos demais sistemas incluem conceitualmente:

- gerar uma posição aleatória dentro do domínio;
- limitar uma posição ao domínio;
- obter as condições ambientais em uma posição.

A câmera não define mais o universo de spawn dos recursos. A câmera é apenas o centro de observação/streaming; os recursos pertencem ao domínio completo. O próprio `WorldResourceSpawner` contém comentário explícito de que não deve copiar os limites da câmera. fileciteturn1079file0

---

## 13. Ambiente

O domínio expõe pelo menos:

- temperatura;
- umidade;
- densidade alimentar;
- stress ambiental derivado.

Esses valores podem ser alterados por ferramentas de experimentação.

O ambiente atual é um laboratório experimental, e as mudanças de ambiente via Tools afetam a simulação corrente.

O sistema procedural de biomas mais antigo foi abandonado para evitar complexidade/desempenho desnecessários. A base atual deve ser considerada **experimental controlada**, não um mundo procedural definitivo.

---

## 14. Comportamento e AI

O comportamento das células foi otimizado para não fazer uma varredura global cara a todo instante.

No caminho otimizado:

- a AI roda em intervalos de aproximadamente `0.15 s`;
- o intervalo é randomizado levemente entre aproximadamente `80%` e `120%` desse valor;
- percepção de células usa índice espacial quando disponível;
- percepção de recursos usa índice espacial quando disponível;
- células com fome aumentam a percepção de recursos em um fator de `2×`;
- existe um período de graça inicial de `15 s` para uma célula recém-criada;
- aliados são determinados pela mesma espécie genética;
- inimigos são filtrados pelo comportamento existente.

A busca de recursos recebe prioridade quando a célula está com fome. Isso foi uma mudança deliberada para aumentar a coerência da sobrevivência e reduzir comportamento desperdiçado. fileciteturn1081file0

---

## 15. Mitose / reprodução

A reprodução ativa atualmente é **mitose**.

Ela continua sendo responsabilidade da simulação/organismo, não dos arquivos `GeneData`/`GeneFormulas`.

Ao criar uma filha por mitose:

1. o progenitor fornece seus dados hereditários;
2. a filha recebe a espécie do progenitor;
3. os genes herdados são normalizados/clonados;
4. a nova célula sofre a etapa de mutação configurada;
5. o fenótipo é aplicado à biologia;
6. a filha é registrada no `CellManager`.

O custo da mitose também participa da sincronização da capacidade energética: `simulation_cell_optimized.gd` garante uma capacidade mínima superior ao próximo custo conhecido de reprodução. fileciteturn1081file0turn1085file0

### Sexual reproduction

**Não implementar neste estado.**

A possibilidade de reprodução sexual foi discutida apenas como ideia futura de design e não faz parte da implementação atual.

---

## 16. CellInspector

Arquivo:

`GPT/CellSystem/cell_inspector.gd`

O Inspector é a ferramenta oficial de inspeção de uma célula.

Interação atual:

- **RMB / botão direito** no mundo seleciona uma célula;
- o Inspector faz um `PhysicsPointQueryParameters2D`;
- procura um corpo no grupo `SimCells` que possua `get_inspection_data()`;
- guarda a referência internamente;
- atualiza um painel fixo no canto superior direito;
- pode também focar a câmera na célula selecionada.

A seleção agora possui a API pública:

`get_selected_cell()`

Essa função retorna a célula selecionada apenas se ela ainda for válida. Isso foi uma correção importante para permitir que as Tools consumam a seleção sem acessar `_selected_cell` diretamente. fileciteturn1082file0

O painel mostra atualmente:

- ID;
- espécie;
- geração;
- parent ID;
- estado;
- dano;
- velocidade;
- tamanho;
- regeneração;
- energia/capacidade;
- fome;
- vários genes;
- características presentes;
- contagem de mitoses;
- próximo custo de mitose;
- stress ambiental.

### Limitação atual do Inspector

`_gene_text()` ainda tenta formatar alelos e fenótipos genéricos como floats.

Isso é inadequado para:

- haplotipos de atributo (`AAAA`, `AaaA`, etc.);
- genes booleanos;
- alguns tipos de dados não-numéricos.

Portanto, a visualização genética ainda precisa de uma etapa de apresentação específica do NEO.

---

## 17. SimulationTools

Arquivos:

- `GPT/CellSystem/simulation_tools.gd`
- `GPT/CellSystem/SimulationTools.tscn`
- arquitetura registrada em `GPT/TOOLS_ARCHITECTURE.md`

A camada Tools é uma interface de experimentação para desenvolvimento e testes científicos.

A arquitetura registrada define a direção:

`Tools UI`
→ `SimulationTools`
→ sistemas já existentes

As Tools não devem ser donas da biologia. fileciteturn1074file0

### Controles atuais

#### Population

- `Spawn Cell`
- `+10` células
- `Spawn Resource`
- `+10` recursos

O spawn individual é modal:

`Normal`
→ ativar `Spawn Cell`
→ clicar no mundo
→ criar célula

ou:

`Normal`
→ ativar `Spawn Resource`
→ clicar no mundo
→ criar recurso.

O clique da ferramenta consome o input antes de conflitar com o pan da câmera.

#### Genetics

- `Mutate`
- `Mutate ×5`
- mostra o alvo selecionado;
- obtém a célula selecionada através de `CellInspector.get_selected_cell()`.

O sistema ainda chama diretamente os métodos internos:

- `_apply_genes_to_biology()`
- `_apply_behavior_genes()`

Isso é funcional, mas arquiteturalmente é um ponto a melhorar. O plano futuro é expor uma API pública estável como `refresh_from_genetics()` na célula, sem fazer Tools conhecer detalhes internos da implementação.

#### Time

- `Pause`
- `1×`
- `2×`
- `4×`
- `8×`

A camada Tools define:

`TICK_DURATION = 0.1`

e mostra:

`1 Tick = 0.1 s of simulation time`

Importante: isso **não é ainda um relógio determinístico de passo fixo**. O tempo real da simulação continua vindo do `delta` dos processos. “Tick” é atualmente uma unidade de apresentação/debug derivada do tempo transcorrido. `Step 1 Tick` continua reservado para uma implementação futura de relógio determinístico. fileciteturn1074file0

#### Environment

- slider de temperatura;
- slider de umidade;
- slider de food density;
- `Reset Environment`.

#### UI

- botão/toggle F4 para abrir/fechar;
- feedback textual;
- indicação do alvo selecionado;
- indicação do modo de spawn.

`SimulationTools` roda com `PROCESS_MODE_ALWAYS`, então sua interface continua processando mesmo quando a simulação está pausada. fileciteturn1084file0

### Limitações atuais das Tools

1. Spawn de recurso cria o node em um ponto validado pelo spawner e depois move esse node para a posição do mouse. Portanto, o teste de espaçamento é feito no ponto inicial, não necessariamente na posição final. Isso pode resultar em sobreposição não intencional.
2. Mutate ainda usa métodos internos da célula.
3. Não existe edição direta de genótipo.
4. Não existe sexual reproduction.
5. Não existe step determinístico de um Tick.
6. Não há ainda uma camada avançada para controlar espécie alvo diretamente.

Esses pontos não invalidam a camada; são apenas trabalho futuro.

---

## 18. TestSimulation / cena integrada

Arquivo:

`GPT/CellSystem/test_simulation.gd`

É a cena integrada de validação do CellSystem.

Ela conecta:

- `CellManager`
- `ResourceSpawner`
- `SimulationCamera`
- `ExperimentalDomain`
- `DebugLayer`
- `CellInspector`

O script define:

`TICK_DURATION = 0.1`

Durante `_process`, ele:

- acumula tempo transcorrido;
- converte o tempo para inteiro de Ticks;
- atualiza FPS quando habilitado;
- permite spawn do player segurando espaço;
- atualiza a telemetria periodicamente;
- conta espécies vivas;
- calcula espécie dominante;
- mostra câmera/domínio/ambiente.

O HUD de debug expõe:

- população atual;
- pico de população;
- births/created;
- deaths derivados;
- mutações;
- geração máxima;
- espécies vivas;
- espécie dominante;
- estado do player;
- posição da câmera;
- raio do domínio;
- temperatura;
- umidade;
- food density.

Os modos adicionais atuais são:

- **P** → Presentation Mode;
- **F3** → FPS debug.

No Presentation Mode o debug layer e a UI do Inspector são escondidos. fileciteturn1086file0

---

## 19. Telemetria

A telemetria populacional atual pertence ao `CellManager`.

Snapshot principal:

- `simulation_time`
- `population`
- `peak_population`
- `total_births`
- `total_deaths`
- `highest_generation`
- `total_mutations`
- `species_count`
- `dominant_species`

O manager também mantém estatísticas por espécie:

- population;
- births;
- deaths;
- peak population;
- highest generation;
- total mutations;
- eliminations.

A ideia geral do sistema de estatísticas foi corrigida anteriormente para não depender de contadores inconsistentes de células destruídas. A população atual deve vir das células registradas e vivas; mortes/created/births devem ser interpretados conforme a instrumentação já existente no manager e no HUD.

---

## 20. Controles atuais conhecidos

| Ação | Controle |
|---|---|
| Pan da câmera | LMB arrastando |
| Inspecionar célula | RMB |
| Zoom | Scroll |
| Presentation Mode | `P` |
| FPS debug | `F3` |
| Simulation Tools | `F4` |
| Spawn player (debug) | Segurar `Space` |

Observação: o spawn do player por `Space` ocorre enquanto a tecla está pressionada e pode resultar em comportamento repetitivo. Isso não é o foco de balanceamento atual.

---

## 21. Estado atual do experimento de balanceamento

Um teste recente foi executado aproximadamente com:

- população inicial: **30**;
- raio do domínio: **7500**;
- recursos iniciais: **7000**;
- pico populacional observado: **106**;
- por volta de `Tick 8700`: população **44**;
- células criadas: **190**;
- mortes: **146**.

Diagnóstico observado:

- produção de alimento parece baixa;
- células acumulam bastante energia;
- população cresce bastante e depois retrai.

Uma grande mudança foi então feita:

**energia armazenada de uma célula morta → drops de recurso**

com máximo de **1000 por pile**.

A hipótese de balanceamento é que isso crie um ciclo energético mais fechado e sustentável:

`food`
→ `stored cellular energy`
→ `survival / movement / reproduction`
→ `death`
→ `world resources`
→ `food`

O primeiro experimento importante da próxima sessão deve ser repetir o mesmo cenário e comparar:

- pico populacional;
- população após o colapso inicial;
- velocidade de recuperação;
- concentração de recursos em hotspots;
- número total de nodes de recurso;
- energia média das células.

---

## 22. Configuração de referência do SimulationConfig

Os valores padrão registrados anteriormente para o cenário integrado são:

- `auto_spawn_cells = false`
- `initial_population = 500`
- `max_population = 10000`
- `initial_resources = 1000`
- `max_resources = 2302`
- `domain_radius = 3000`
- `simulation_time_limit = 0`

O `test_simulation.gd` aplica essas configurações separadamente a `CellManager`, `ResourceSpawner` e `ExperimentalDomain`. fileciteturn1086file0

**Atenção:** como `max_resources` limita nodes, um teste com `initial_resources = 7000` exige também `max_resources >= 7000` para realmente manter 7000 nodes iniciais pela lógica normal do spawner.

---

## 23. Problemas históricos que NÃO devem ser reintroduzidos

### 23.1 Geração procedural cara

O experimento procedural antigo de ambiente/biomas foi abandonado. Não voltar a essa arquitetura sem necessidade real.

### 23.2 Shader procedural pesado

Um experimento de shader foi removido devido a problemas de compilação/desempenho.

### 23.3 Visual de recursos caro

A representação de recursos foi reduzida a dois círculos baratos. Não reintroduzir efeitos visuais caros antes de medir performance.

### 23.4 Sistema de lineage/tree

O sistema antigo de genealogia visual foi removido.

Arquivos antigos removidos anteriormente incluem:

- `lineage_popup.gd`
- `lineage_graph.gd`
- `cell_record_popup.gd`
- `cell_portrait.gd`
- `genetics_popup.gd`

`parent_id` e `generation` continuam existindo porque são úteis para genética/estatística, mas o antigo sistema de árvore visual não existe mais.

### 23.5 Compartilhamento de GeneData entre pai e filho

Um bug conceitual foi corrigido: genética herdada não deve apontar para os mesmos `RefCounted` mutáveis do progenitor.

A normalização agora reconstrói `GeneData` a partir de dicionário.

---

## 24. Hashes/versões importantes

### Base NEO

`7756af0408c33d434f382b07c034570405937ecb`

### Getter público do Inspector

Commit associado:

`742adf62...`

Arquivo:

`GPT/CellSystem/cell_inspector.gd`

Content SHA registrado:

`2061f6620f4a5a627b39c7f819ca245b874d89cc`

### Death drop inicial

`0db0087e...`

### Cell.die() convertido para drop de energia

`89a6267503...`

`cell.gd` content SHA atual:

`e074628f75e76a9b1e2686344a0aacde1c6de42f`

### Optimized cell desativa kill reward antigo

`4f253091...`

`simulation_cell_optimized.gd` content SHA atual:

`a1033899139cfb19666dc0667002aa8b51c9c3c1`

### Última simplificação dos death drops

`b7b9a155...`

`world_resource_spawner.gd` content SHA atual:

`30ee3cc3a7ef5ef85916d8667a41fac4bebffc01`

### GeneSystem atual

`cell_genetics.gd` content SHA:

`caf13695abf10f1c5b355bb4308e79dd0d0e7a0e`

`gene_data.gd` content SHA:

`08a7cd5f1617e1b5ef652b968e37d388caefec45`

`gene_formulas.gd` content SHA:

`4042829af07f725c19d9d5196625d55e24ede77b`

---

## 25. Próxima prioridade recomendada

A sequência mais segura para a próxima sessão é:

### A. Repetir o experimento econômico

Usar exatamente o mesmo cenário do teste recente para comparar a nova economia de morte.

### B. Medir o ciclo de energia

Observar energia média, capacidade média, comida disponível, mortes por fome e sobrevivência após quedas populacionais.

### C. Balancear NEO sem reescrever NEO

A prioridade mais promissora é fazer os genes existentes significarem mais no gameplay sem criar categorias novas.

Especialmente:

- aplicar `efficiency` à economia de energia;
- avaliar custo de size;
- avaliar gasto de movimento;
- avaliar custo de mitose;
- calibrar valor dos resources;
- calibrar capacidade energética.

### D. Melhorar a apresentação genética

Fazer o Inspector distinguir:

- haplótipo/sequência de atributo;
- genes numéricos;
- genes binários;
- fenótipo expresso.

### E. Melhorar a API das Tools

Criar uma API pública de refresh genético na célula e remover chamadas diretas a métodos privados.

---

## 26. Regras para continuidade

Ao continuar este projeto:

1. **Não reestruturar NEO inteiro sem necessidade.**
2. **Não criar sexual reproduction agora.**
3. **Não voltar ao procedural/shader pesado sem necessidade.**
4. **Preferir mudanças incrementais de baixo risco.**
5. **Alterar uma variável de balanceamento por experimento sempre que possível.**
6. **Manter `CellInspector` como dono oficial da seleção.**
7. **Tools deve consumir APIs públicas, não possuir biologia.**
8. **Preservar energia em drops de morte; não descartar energia silenciosamente.**
9. **Monitorar quantidade de nodes de recursos, porque death drops podem ultrapassar `max_resources`.**
10. **Tratar `efficiency` como importante próxima peça do balanceamento, mas sem mudar a definição genética existente.**

---

## 27. Resumo de uma frase

**Alive Cells está atualmente com um ecossistema circular funcional, genética NEO estruturada em atributos por haplótipos/loci + adaptações + características binárias, metabolismo/mitose/AI/telemetria integrados, uma economia nova em que a energia armazenada de células mortas retorna ao mundo como recurso em piles de no máximo 1000, e uma camada de Tools dedicada a experimentação — estando a fase atual focada principalmente em balanceamento e polimento.**
