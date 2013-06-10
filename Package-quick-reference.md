# Quick reference sheet for package process

in progress

## Controlling the package

Create a new package
> create("mypackage")
Then copy R sources to the R directory

## developing the package

Re-loading the package during development
> load_all("./mypackage")

Note that you need to make sure dependent libraries are manually loaded

## locally deploying

### Building the package for all users of the system

Change to the path of the package
> document()
> install()

Check the error messages!

