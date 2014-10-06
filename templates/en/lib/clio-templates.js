ClioTemplates = {
    feed: {
        '.l_entry': {'entry<-entries': {
            //'.profile a@href': 'http://friendfeed.com/#{entry.from.id}',
            //'.profile img@title': 'entry.from.name',
            //'.profile@class+': function(o){return o.item.to === undefined ? 'hidden' : ''},
            
            '.ebody .name a': 'entry.from.name',
            '.ebody .name a@href': 'http://friendfeed.com/#{entry.from.id}',
            '.ebody .name@class': function(o){return o.item.to === undefined ? 'hidden' : 'name'}, // class+ somehow didn't work
            
            /*'+.comments.middle_comments': function(o){return o.hiddenComments ? "<a>Show " + (o.item.hiddenComments.length) + " more comments</a>" : ""},

            '.comments.all_comments@view': function(o){console.log(o.item); return o.item.comments ? '' : 'hidden'},
            '.comments.first_comment@view': function(o){return o.item.firstComment ? '' : 'hidden'},
            '.comments.last_comment@view': function(o){return o.item.lastComment ? '' : 'hidden'},
            '.comments.middle_comments@view': function(o){return o.item.hiddenComments ? '' : 'hidden'},*/
            
            '.ebody .text': 'entry.body',

            '.ebody .images.media .container': {'thumbnail<-entry.thumbnails':{
                'a img@src': 'thumbnail.url',
                'a@href': 'thumbnail.link',
                'a img@style': 'width:#{thumbnail.width}; height:#{thumbnail.height};'
            }},
            
            '.ebody .images.media@class+': function(o){return o.item.thumbnails ? '' : ' hidden'},

            '.info .date': 'entry.dateFriendly',
            '.info .date@href': './entry.html?id=#{entry.name}',

            '.info .via@class+': function(o){return o.item.via ? '' : ' hidden'},
        
            '.info .service': 'entry.via.name',
            '.info .service@href': 'entry.via.url',

            '.likes .lbody': {'like<-entry.likes':{
                '.l_profile': 'like.from.name',
                '.l_profile@href': 'http://friendfeed.com/#{like.from.id}',
                '.l_profile@title': 'like.dateFriendly'
            }},

            /* between 1 and 3 comments */
            '.comments.all_comments .comment': {'comment<-entry.comments':{
                '.quote@title': 'comment.dateFriendly',
                '+.content': 'comment.body',
                '.content .l_profile': 'comment.from.name',
                '.content .l_profile@href': 'http://friendfeed.com/#{comment.from.id}'
            }},

            /* > 3 comments */
            '.comments.first_comments .comment': {'comment<-entry.firstComments':{
                '.quote@title': 'comment.dateFriendly',
                '+.content': 'comment.body',
                '.content .l_profile': 'comment.from.name',
                '.content .l_profile@href': 'http://friendfeed.com/#{comment.from.id}'
            }},

            '.comments.last_comments .comment': {'comment<-entry.lastComments':{
                '.quote@title': 'comment.dateFriendly',
                '+.content': 'comment.body',
                '.content .l_profile': 'comment.from.name',
                '.content .l_profile@href': 'http://friendfeed.com/#{comment.from.id}'
            }},
            
            '.comments.middle_comments .hidden_comments_contents .comment': {'comment<-entry.hiddenComments':{
                '.quote@title': 'comment.dateFriendly',
                '+.content': 'comment.body',
                '.content .l_profile': 'comment.from.name',
                '.content .l_profile@href': 'http://friendfeed.com/#{comment.from.id}'
            }}
        }}
    },

    entry: {
        '.profile a@href': 'http://friendfeed.com/#{from.id}',
        '.profile img@title': 'from.name',
        '.ebody .name a': 'from.name',
        '.ebody .name a@href': 'http://friendfeed.com/#{from.id}',

        '.ebody .text': 'body',
        
        '.ebody .images.media .container': {'thumbnail<-thumbnails':{
            'a img@src': 'thumbnail.url',
            'a@href': 'thumbnail.link',
            'a img@style': 'width:#{thumbnail.width}; height:#{thumbnail.height};'
        }},
        
        '.ebody .images.media@class+': function(o){return o.context.thumbnails ? '' : 'hidden'},
        
        '.info .date': 'dateFriendly',
        '.info .date@href': 'url',
        
        '.info .via@class+': function(o){return o.context.via ? '' : ' hidden'},
        
        '.info .service': 'via.name',
        '.info .service@href': 'via.url',
        
        '.comments': {'comment<-comments':{
            '.quote@title': 'comment.dateFriendly',
            '+.content': 'comment.body',
            '.content .l_profile': 'comment.from.name',
            '.content .l_profile@href': 'http://friendfeed.com/#{comment.from.id}'
        }},
        '.likes .lbody': {'like<-likes':{
            '.l_profile': 'like.from.name',
            '.l_profile@href': 'http://friendfeed.com/#{like.from.id}',
            '.l_profile@title': 'like.dateFriendly'
        }}
        
    },
    
    sidebarGroupedIndexes: {
        '.box': {'index<-indexes': {
            '.title a': 'index.meta.title',
            '.title a@href': './index.html##{index.meta.descriptor}',
            
            '.box-body .group': {'group<-index.groups': {
                '.group-title a': 'group.title',
                'ul li': {'row<-group.rows': {
                    'a': 'row.title',
                    'a@href': './list.html?index=#{index.meta.descriptor}&term=#{row.descriptor}'
                }}
            }}
        }}
    },
    
    sidebarPlainIndexes: {
        '.box': {'index<-indexes': {
            '.title a': 'index.meta.title',
            '.title a@href': './index.html##{index.meta.descriptor}',
            
            '.box-body ul li': {'row<-index.rows': {
                'a': 'row.title',
                'a@href': './list.html?index=#{index.meta.descriptor}&term=#{row.descriptor}'
            }}
        }}
    },

    sidebarSubindex: {
        '.title a': 'index.meta.title',
        '.title a@href': './index.html##{index.meta.descriptor}',
        
        '.box-body ul li': {'row<-index.rows': {
            'a': 'row.title',
            'a@href': './list.html?index=#{index.meta.descriptor}&term=#{row.descriptor}'
        }}
    },
    
    pager: {
        '#pages a': {'page<-pages': {
            '.': 'page.title',
            '@href': 'page.url',
            '@class': 'page.class'
        }}
    }
    
}
