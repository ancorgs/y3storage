# My Crystal Experiment

For a very long time, I have been planning to play with [Crystal](https://crystal-lang.org)
as possible substitute/complement for [Ruby](https://www.ruby-lang.org). With
that goal, I have isolated a very small subset of the [Ruby project I know the
best](https://github.com/yast/yast-storage-ng) and I'm migrating it to Crystal
to get a general feeling about the language.

## Content of the repository

### The `ruby` directory

It's basically a small subset of yast-storage-ng with all dependencies removed.
That mainly means no calls to the YaST logger or any other YaST API, no
localization (which also depended on YaST and on gettext), no UI and no
interaction with libstorage-ng.

Other than removing dependencies, the goal of this directory is to be as
faithful to the real yast-storage-ng as possible, even for those classes or
RSpec tests that are not exactly an example of Ruby/RSpec correctness.

The tests can be executed in any system with Ruby installed by simply running:

```
cd ruby
rake test
```

### The `crystal` directory

The plan is to populate this directory with the Crystal equivalence to the
`ruby` one, step by step. Since the main goal is to check how Crystal "feels"
compared to Ruby, the conversion is done trying to perform the very minimum set
of changes. For example, explicit type definitions are added only when needed or
when they allow to remove guard clauses.

Displaying every Crystal class and test alongside its corresponding Ruby/RSpec
one should clearly show the similarities and differences between both languages.

The tests can be executed in any system with Crystal and `make` installed by
simply running:

```
cd crystal
make test
```

## License

Obviously, this project is available under the very same conditions than the
original yast-storage-ng.
