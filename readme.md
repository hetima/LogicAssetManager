#LogicAssetManager

LogicAssetManager is resource switcher for Logic Pro X.

##Features

- No needs backup original files
- Loads multiple theme together
- Variant options in single theme
- Customizing instrument icons

##Details
LogicAssetManager replaces resources by switching symbolic link destination in each framework. So original resources are not modified.  
`MAResources.framework/Resources` points to `./Versions/Current/Resources` by default. LogicAssetManager changes this destination to own compiled directory.

##System Requirements

- OS X 10.9
- Logic Pro X


## Author

http://hetima.com/  
https://twitter.com/hetima

##License

MIT License.
