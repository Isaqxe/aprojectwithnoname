# Cell Creation Prototype

Protótipo conceitual da tela de criação da célula do **Alive Cells**.

## Fluxo

1. O jogador escolhe o tipo celular:
   - **Procarionte** — estrutura mais simples.
   - **Eucarionte** — estrutura mais complexa, com núcleo.
2. A célula selecionada é exibida usando o mesmo princípio de geração visual procedural usado pelas ameaças.
3. A personalização visual poderá futuramente controlar parâmetros como forma, cor e tamanho.
4. A definição de atributos genéticos (HP, velocidade etc.) fica separada desta etapa e será integrada posteriormente.

## Protótipo de interface

```text
┌─────────────────────────────────────────────────────────┐
│                 CRIE SUA CÉLULA                         │
│                                                         │
│          TIPO CELULAR                                   │
│                                                         │
│       ┌─────────────┐       ┌─────────────┐             │
│       │ PROCARIOTE  │       │ EUCARIOTE   │             │
│       │     ●       │       │    ◉        │             │
│       │  simples    │       │  com núcleo │             │
│       └─────────────┘       └─────────────┘             │
│                                                         │
│                  SUA CÉLULA                             │
│                    ◉                                    │
│                                                         │
│       Forma       ◄────────●────────►                   │
│       Cor         ◄────────●────────►                   │
│       Tamanho     ◄────────●────────►                   │
│                                                         │
│                   [ CONFIRMAR ]                         │
└─────────────────────────────────────────────────────────┘
```

> Este arquivo é um protótipo de design. Não representa ainda uma implementação funcional no Godot.

## Direção de design

A aparência do Player deve compartilhar o mesmo sistema visual procedural das células inimigas, evitando que o protagonista pareça pertencer a outro jogo. As diferenças entre tipos celulares devem ser representadas por regras do gerador, não por sprites completamente independentes.
