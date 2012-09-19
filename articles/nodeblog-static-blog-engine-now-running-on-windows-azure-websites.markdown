Title: Nodeblog static blog engine now running on Windows Azure Web Sites
Author: Matias Woloski
Date: Tue Sept 19 2012 12:10:35 GMT-0300
Node: v0.6.2

When Windows Azure added support for node.js a year ago, we thought that it would be a good idea to try hosting a static blog engine on a worker role running node. So after some research we've found [wheat](https://github.com/qraftlabs/wheat) and after some [hacking here and there](running-wheat-git-based-blog-engine-on-windows-azure) we were able to run a git repo on the worker role and accept a github hook notification whenever content was pushed to <https://github.com/woloski/nodeonazure-blog>. 

## What has changed?

With the introduction of [Windows Azure Web Sites](https://www.windowsazure.com/en-us/home/scenarios/web-sites/) and its support of node.js and link your website with Github hoook, this was not needed anymore. We can now edit our articles in markdown, commit them to github and Windows Azure will pick the changes and update the website with the new content.

We had to tweak wheat a little bit so it does not rely on git at all. [Wheat](https://github.com/qraftlabs/wheat) supports working on a bare repo or directly reading from the file system. However, there were some places in the code where it was trying to still call `git.exe` to get the revisions of an article (for instance). For this to run on a Windows Azure worker role we had to add startup tasks and what not, with Windows Azure Web Sites none of that was required. Simplification! 

And look, we can even execute some code!

<running-wheat-git-based-blog-engine-on-windows-azure/test.js*>

Thanks [@jfromaniello](http://twitter.com/jfromaniello) for the great tip of using npm link on nested modules to debug locally the changes on the forks.

Thanks [@tjanczuk](http://twitter.com/tjanczuk) and [@johnnyhalife](http://twitter.com/johnnyhalife) for your help while troubleshooting npm install hicups.

The modified version of wheat is [here](https://github.com/qraftlabs/wheat) or you can start by [cloning the repo](https://github.com/woloski/nodeonazure-blog) with all the styles/layout/etc.