<h1 align="center">Axis (em alpha ⚠️)</h1>

(Versão em inglês)[README_EN.md]

**Axis** é uma ferramenta de linha de comando para padronização de mensagens de commit em projetos Git. Ela permite definir formatos de commit personalizados a partir de um arquivo de configuração YAML.

## Instalação
Por agora ainda não existe um binário a disponibilizar. então você deverá compilar o projeto da fonte.

### Pré-requisitos
- Ocaml
- Dune
- Os pacotes [Core](https://ocaml.org/p/core/latest), [Yaml](https://ocaml.org/p/yaml/latest/doc/Yaml/index.html) e [Cmdliner](https://ocaml.org/u/f06857371084eb01bbf1461eed1e6df0/cmdliner/1.0.4/doc/Cmdliner/index.html)

## Funcionalidades
Atualmente o programa só possui um commando, que é o de formatar. Mas como isso é feito?

O Axis lê um arquivo no seu diretório atual do terminal (a.k.a. o comando `pwd` no Linux) chamado `.axis.yaml`, onde estarão todas as configurações referentes à formatação da sua mensagem de commit. O formato esperado é:

```yaml
variables:
  nome_da_variavel: valor
  outra_variavel: outro_valor

templates:
  Fix:
    pattern: "{nome_da_variavel} {message}. Sem mais manutenção"
    prefix: "[FIX]"
    suffix: "Feito por <algum nome de time do trabalho>"
```

Destrinchando eessa configuração de cima para baixo, temos:

#### Variáveis
Formas de armazenar um valor para compartilhar entre padrões ou agilizar o processo de escrita. O campo onde serão declaradas as varáveis deve receber o nome "variables", exatamente como está no exemplo.

#### Templates
São os padrões de mensagens totalmente customizáveis. Cada template deve conter:
- Um nome, para que seja utilizada;
- um padrão da mensagem, nomeado `pattern`, que representa a forma como sua mensagem será formatada;
- Um prefixo para a sua mensagem, chamado `prefix`;
- Um sufixo para a sua mensagem, chamado `suffix`;

As templates funcionam de forma be simples: tudo que está entre chaves é uma **variável**. A única exceção é `{message}`, que representa a mensagem definida pelo usuário ao invocar o programa.

Por motivos óbvios, variáveis não devem ser declaradas usando palavras reservadas do arquivo de configuração, como `message` ou `pattern`.

## Contribuição

Contribuições são bem-vindas! Para contribuir:

1. Faça um fork do repositório.
2. Crie uma branch para sua feature/fix: git checkout -b minha-feature.
3. Faça as alterações e commit seguindo um formato adequado.
4. Envie um pull request.
