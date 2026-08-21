# Cell Creation — estrutura modular

Estrutura planejada para a tela de criação da célula do Alive Cells.

```text
CellCreation
├── Background
├── MainPanel
│   ├── Title
│   ├── TypeSelection
│   │   ├── ProkaryoteButton
│   │   └── EukaryoteButton
│   ├── CellInfo
│   │   ├── TypeLabel
│   │   └── DescriptionLabel
│   ├── Appearance
│   │   ├── Size
│   │   │   ├── Label
│   │   │   └── Slider
│   │   ├── Color
│   │   │   ├── Label
│   │   │   └── ColorPicker
│   │   └── Shape
│   │       ├── Label
│   │       └── Button
│   └── ConfirmButton
└── CellPreview
```

## Princípio

A cena deve conter os elementos da interface. O script deve apenas controlar comportamento e estado.

A estrutura foi preparada para que cada seção possa ser alterada no editor do Godot sem reconstruir a UI por código.

## Responsabilidades

- `CellCreation`: coordena seleção e confirmação.
- `TypeSelection`: controla o tipo celular.
- `Appearance`: controla parâmetros visuais.
- `CellPreview`: exibe a célula proceduralmente.
- Futuramente, `CellData`: concentrará os dados da célula, incluindo características genéticas.

Esta estrutura é provisória e não implementa ainda genética, mutações ou hereditariedade.
