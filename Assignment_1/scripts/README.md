# Plotting the FSM

Install graphviz to your python env or default user.

```sh
pip install graphviz
```

Create the `gcd_fsm.dot` file and then export an image by running:
To create the images from the `.dot` file run:
```sh
dot -Tpng -Gdpi=300 gcd_fsm.dot -o gcd_fsm.png
```

See more on [https://graphviz.org/doc/info/command.html](docs).
