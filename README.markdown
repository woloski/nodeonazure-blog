# nodeblog.azurewebsites.net

This is a community supported blog about how to program in nodejs on top of Windows AZure.

This is powered by a new static blog engine written in node called [wheat][].

To run a local version of the blog, simply clone the repo and run `npm install`

[wheat]: http://github.com/creationix/wheat

## Contributing

The best way to contribute is to fork this repository and add your article.  If this is your first article, then please add an entry for yourself in the authors directory as well.

### Article format

Every article is a markdown file with some meta-data at the top of the file.

    Title: Hello World node in Azure
    Author: Matias Woloski
    Date: Thu Feb 04 2010 02:24:35 GMT-0600 (CST)
    Node: v0.6.6

    Running node in Azure is very simple...

    ## First section: Display JavaScript files
    
    * display contents of external JavaScript file (path is relative to .markdown file)
    <test-code/test-file.js>

    * display contents of external JavaScript file and evaluate its contents 
    <test-code/evaluate-file.js*>

    More content goes here.

## Licensing

All articles are copyright to the individual authors.  Authors can put notes about license and copyright on their individual bio pages if they wish.