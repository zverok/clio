What is it
--------

Backup tool for your FriendFeed.

How to use it
-------------

You will need Ruby v1.9 or newer.

Clone repository or download it to some folder.

Then, in command line (or Terminal):

`ruby bin/clio-en.rb -u (username) -k (remote key) -f (list of feeds to load)`

(remote key) can be received here: http://friendfeed.com/remotekey

If you'll ommit -f, it will download your own feed.

Options (you can also see them with: `ruby bin/clio-en.rb -h`):

    -u, --user           Your username
    -k, --key            Your remote key from http://friendfeed.com/remotekey
    -f, --feeds          Feeds to load, comma-separated: user1,group2,user3 (your own feed by default)
    -p, --path           Path to store feeds, by default its `result`, with each feed at <path>/<feed>
    -l, --log            Path to write logs (STDOUT by default)
    -d, --dates          If this flag provided, adds current date to folder name: <path>/<feed>/<YYYY-MM-DD> (useful for scheduled backups)
    -i, --indexonly      Index only (data already loaded)
        --depth          Depth of download (how many new entries to download); maximum possible (~10'000) by default
        --zip            Pack into archive <path>/<feed>-<YYYY-MM-DD>.zip
    -I, --images         If this flag is provided, images from friendfeed-media server will be downloaded
    -h, --help           Display this help message.

### Result

That's it!

Now in folders like result/(feed name) you'll have index.html — just open it in browser.

* It works seemlessly in Firefox.
* To see it with Opera: check an option <a href="opera:config#UserPrefs|AllowFileXMLHttpRequest">opera:config#UserPrefs|AllowFileXMLHttpRequest</a>.
* To see it with Chrome: you should run your browser with --allow-file-access-from-files.

Or, you can run:

`ruby bin/server.rb (юзернейм)`

And it will start simple server at http://localhost:65261/index.html, available from any browser.

Or, if you'll upload everything on some server, you'll be able to see it (all browser hacks are only for "local" files).

FYI, all your entries are stored in separate JSON files in your feed folder, so, if you are programmer, you can do something useful about it.
