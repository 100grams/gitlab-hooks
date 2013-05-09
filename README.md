Gitlab Hooks, yo!
=================

These are the hooks that we use to post to Asana and send a message to
HipChat whenever we push to a GitLab repository.

To use this simply fill out the env.rb file with the required
credentials.

Mention the Asana task ID in your commit, like `This commit is about #1234566776`, and this will post a message to that task.

If you mention something about fixing it, like `This commit fixes #12342134213`, this will close that task.

All of the commits will be posted to HipChat.

