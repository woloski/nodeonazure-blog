Title: Welcome 
Author: Matias Woloski
Date: Tue Jan 02 2012 12:10:35 GMT-0300
Node: v0.6.6

**nodeblog.cloudapp.net** is a website that shows articles related to node.js + Windows + Windows Azure. I started working with node last year together with [Angel Lopez](https://github.com/ajlopez) at [Southworks](http://blogs.southworks.net) while helping [Microsoft](http://www.microsoft.com) to implement the backend of an online HTML5 game [tankster.net](http://www.tankster.net)... 

## A bit of history

I started working with node last year together with [Angel Lopez](https://github.com/ajlopez) at [Southworks](http://blogs.southworks.net) while helping [Microsoft](http://www.microsoft.com) to implement the backend of an online HTML5 game [tankster.net](http://www.tankster.net). We started reading about node and inmediately got hooked, for good or bad this is a game-changer technology. 
For that project in particular we used the [socket.io](http://socket.io) library. With just 10 lines of code we were able to relay commands between different browsers with WebSockets or long polling. That's powerful :)

Since then I got interested in node.

### Contributing to the community

The node community is vibrant. There are more than 6000 packages in [npm](http://npmjs.org), dozens of blogs, questions in [StackOverflow](http://stackoverflow.com/questions/tagged/node.js) and more than 7000 repos in [github](https://github.com/search?type=Repositories&language=JavaScript&q=node&repo=&langOverride=&x=0&y=0&start_value=1). So much contribution push more contribution, it's a virtuous loop.

### The goal of this site

The intent of this website is to share anything related to node in the context of Windows and in the context of the Microsoft cloud platform, [Windows Azure](http://windows.azure.com). Node in Windows is in its infancy so it's a good opportunity to share what we are learning throughout the process! 

## Choosing a blog engine

Last time I looked at blog engines was back in 2005 when [CommunityServer](http://telligent.com/) was the hype :). It turns out that the world has evolved for good and there is a new trend in the 'geek world' where blogs are backed with git. Yes, [git](http://git-scm.com), the distributed source control.
 
I played with [octopress](http://octopress.org) which is based on [jekyll](https://github.com/mojombo/jekyll) and got it up and running in minutes. However octopress runs on Ruby and even though it could run on Azure, it's not native like Node.js and it involves more steps. Also, if people wants to run it locally on Windows they will have to install Ruby.

Weeks later while reading an article in [howtonode.org](http://howtonode.org), I've found they were running [wheat](http://github.com/creationix/wheat). I tried it on my Mac and then on my Windows VM and it worked flawlessly. I had to do a couple of things to run it on Windows Azure, and that's subject for an article by itself.

## Contributing to this blog

Enough said, I hope you enjoy it and if you want to contribute, the doors are open. The process of writing an article makes use of the git workflow and github usability shortcuts. Here it is:

1. Fork the [github repo](https://github.com/woloski/nodeonazure-blog)
2. Add a new article on your fork under `/articles` using markdown and add yourself as an author `/authors` 
3. (optionally) preview it locally `node server.js` and browse to `http://localhost:1337` 
4. When you are done, push to your repo and send a pull request. The projects contributors (currently [my self](https://github.com/woloski) and [ajlopez](https://github.com/ajlopez)) will pull it and it will be published online at [nodeblog.cloudapp.net](http://nodeblog.cloudapp.net)

Happy node on Windows!