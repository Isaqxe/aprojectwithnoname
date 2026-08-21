# Estrutura modular da CellCreation

A cena funcional deverá ser organizada assim:

```text
CellCreation (Control)
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
│   │   └── Size
│   │       ├── SizeLabel
│   │       └── SizeSlider
│   └── ConfirmButton
└── CellPreview
```

Os nós referenciados pelo controlador devem possuir `unique_name_in_owner`, permitindo acesso por `%NomeDoNode` sem depender de caminhos frágeis.

A cena continua sendo responsável pelo layout. O script apenas conecta sinais e altera estado.
