# Alive Cells — Biome System (Design / Prototype)

> **Somente planejamento.** Este arquivo descreve uma possível arquitetura para um sistema de biomas procedural. Não é uma implementação funcional.

## Relação com os objetivos atuais

O próximo objetivo oficial do `objectivesprototype.txt` continua sendo:

> **☐ Sistema básico de sobrevivência/dano**

O sistema de biomas não deve bloquear esse objetivo. Ele é uma camada futura que pode enriquecer o mapa depois que sobrevivência, dano e morte estiverem funcionando.

## Conceito

O mapa deixa de ser apenas uma arena delimitada e passa a representar um **microambiente** com regiões diferentes.

Cada bioma possui um conjunto pequeno de regras que determina:

- aparência da região;
- recursos predominantes;
- ameaças predominantes;
- condições ambientais;
- possíveis vantagens/desvantagens para a célula.

A primeira versão deve ser deliberadamente simples.

## Arquitetura proposta

```text
ProceduralMapGenerator
        |
        +--> BiomeGenerator
        |       |
        |       +--> Biome A
        |       +--> Biome B
        |       +--> Biome C
        |
        +--> ResourceSpawner
        |
        +--> EnemySpawner
        |
        +--> EnvironmentController
```

### `ProceduralMapGenerator`

Responsável pela estrutura espacial do mapa.

Deve:

- receber uma `seed`;
- definir tamanho/limites do mapa;
- dividir o espaço em regiões;
- informar qual região/bioma ocupa determinada posição.

Não deve decidir diretamente quais inimigos ou recursos existem.

### `BiomeDefinition`

Pode futuramente ser um `Resource` do Godot para tornar os biomas ajustáveis pelo Inspector.

Exemplo conceitual:

```text
BiomeDefinition
├── id
├── display_name
├── visual_color
├── resource_types
├── enemy_types
├── environmental_damage
├── movement_modifier
├── collection_modifier
└── special_rules
```

Isso permitiria criar novos biomas alterando dados, em vez de duplicar código.

### `BiomeGenerator`

Escolhe e distribui os biomas no mapa.

Para o protótipo, a distribuição pode ser baseada em regiões simples:

```text
┌─────────────┬──────────────┐
│   BIOMA A   │   BIOMA B    │
│             │              │
│  recursos   │  ameaça      │
│  comuns     │  especial    │
├─────────────┼──────────────┤
│   BIOMA C   │   BIOMA A    │
│             │              │
│ condição    │  recursos    │
│ hostil      │  comuns      │
└─────────────┴──────────────┘
```

Depois podemos substituir isso por ruído procedural ou outro método de geração orgânica, sem alterar a interface dos dados do bioma.

## Regra de interação

O Player deve conseguir consultar o bioma onde está.

```text
Player.position
      ↓
BiomeManager
      ↓
BiomeDefinition
      ↓
efeitos do ambiente
```

Isso é preferível a colocar verificações de bioma espalhadas pelo código do Player.

## Exemplos de biomas iniciais

### Região rica

- alta concentração de moléculas;
- poucas ameaças;
- sem penalidade ambiental.

### Região hostil

- menor concentração de recursos;
- ameaça mais frequente ou diferente;
- pode causar dano periódico.

### Região especializada

- recurso exclusivo;
- condição ambiental específica;
- favorece determinada característica/mutação.

Não precisamos de mais do que 2–3 biomas no primeiro protótipo.

## Conexão com mutações

Um bioma pode fornecer uma razão para determinada mutação ser útil.

```text
BIOMA HOSTIL
      ↓
condição ambiental
      ↓
penalidade
      ↓
mútação adaptativa
      ↓
maior sobrevivência
```

Importante: a mutação não deve ser simplesmente uma chave que “desbloqueia” o bioma. Ela pode apenas reduzir uma desvantagem, preservando a ideia de adaptação.

## Recursos por bioma

O `ResourceSpawner` pode consultar o bioma antes de criar uma molécula:

```text
posição escolhida
      ↓
BiomeManager
      ↓
lista de recursos permitidos
      ↓
sorteio do recurso
```

Assim certos recursos podem existir apenas em determinadas regiões.

## Inimigos por bioma

O mesmo princípio pode ser aplicado ao `EnemySpawner`:

```text
posição de spawn
      ↓
bioma
      ↓
tipos de célula permitidos
      ↓
sorteio do tipo
```

Isso permite que diferentes regiões tenham populações diferentes sem criar um spawner totalmente separado para cada bioma.

## Performance

A primeira versão deve evitar consultar sistemas complexos por frame.

Preferência:

- descobrir o bioma atual do Player apenas quando ele mudar de região;
- usar dados pré-calculados para a distribuição;
- evitar criar um Node individual para cada pequeno pedaço do mapa;
- manter as definições de bioma como dados reutilizáveis.

## Seed

O mapa deve poder ser reproduzido a partir de uma seed.

```text
seed
 ↓
biomas
 ↓
recursos
 ↓
inimigos
 ↓
visual do mapa
```

Isso facilita testes, depuração e demonstrações na feira.

## Ordem de implementação sugerida

### Fase 0 — prova visual

Criar um mapa de teste com 2–3 regiões claramente diferentes.

### Fase 1 — identificação

Fazer o jogo conseguir responder: “em qual bioma o Player está?”.

### Fase 2 — recursos

Fazer os recursos respeitarem as regras do bioma.

### Fase 3 — ameaças

Fazer o spawner respeitar as regras do bioma.

### Fase 4 — condições

Adicionar uma condição ambiental simples que afete o Player.

### Fase 5 — genética

Usar o sistema de atributos/mutações para reduzir ou alterar os efeitos ambientais.

## Limites de escopo

Não implementar inicialmente:

- simulação química detalhada;
- clima dinâmico;
- dezenas de biomas;
- ecossistema completo;
- IA específica para cada bioma;
- física ambiental complexa.

O objetivo é produzir a sensação de um **microambiente com regiões distintas**, não simular uma biosfera inteira.

## Princípio central

> **O ambiente deve criar uma razão para a célula possuir certas características.**

Isso permite conectar diretamente:

```text
ambiente → sobrevivência → característica → mutação → hereditariedade
```

sem tornar o sistema de biomas obrigatório para o funcionamento básico do jogo.