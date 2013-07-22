Gitlab Hooks, yo!
=================

These are the hooks that we use to post to Asana and send a message to
HipChat whenever we push to a GitLab repository.

To use this simply fill out the env.rb file with the required credentials.

Run this app from any machine like so: `ruby gitlab-hooks.rb -e production` After that you can set up your hook in gitlab like this:
`http://your.domain:4567?room=myroom&color=purple` where the room paramater specifies the HipChat room that will be posted to and the color param specifies the color the message will have (will default to yellow).

Mention the Asana task ID in your commit, like `This commit is about #1234566776`, and this will post a message to that task.

If you mention something about fixing it, like `This commit fixes #12342134213`, this will close that task.

All of the commits will be posted to HipChat.

