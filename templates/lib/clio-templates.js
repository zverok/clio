ClioTemplates = {
    feed: {
        '.l_entry': {'entry<-entries': {
            '.profile a@href': 'http://friendfeed.com/#{entry.from.id}',
            '.profile img@title': 'entry.from.name',
            '.ebody .name a': 'entry.from.name',
            '.ebody .name a@href': 'http://friendfeed.com/#{entry.from.id}',
            '.ebody .text': 'entry.body',

            '.info .date': 'entry.dateFriendly',
            '.info .date@href': './entry.html##{entry.name}',

            '.likes .lbody': {'like<-entry.likes':{
                '.l_profile': 'like.from.name',
                '.l_profile@href': 'http://friendfeed.com/#{like.from.id}',
                '.l_profile@title': 'like.date'
            }},

            '.comments': {'comment<-entry.comments':{
                '.quote@title': 'comment.dateFriendly',
                '+.content': 'comment.body',
                '.content .l_profile': 'comment.from.name',
                '.content .l_profile@href': 'http://friendfeed.com/#{comment.from.id}'
            }},
        }}
    },

    entry: {
        '.ebody .text': 'body',
        
        '.info .date': 'dateFriendly',
        '.info .date@href': 'url',
        
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
            '.l_profile@title': 'like.date'
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
                    'a@href': './list.html##{index.meta.descriptor}:#{row.descriptor}'
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
                'a@href': './list.html##{index.meta.descriptor}:#{row.descriptor}'
            }}
        }}
    },

    sidebarSubindex: {
            '.title a': 'index.meta.title',
            '.title a@href': './index.html##{index.meta.descriptor}',
            
            '.box-body ul li': {'row<-index.rows': {
                'a': 'row.title',
                'a@href': './list.html##{index.meta.descriptor}:#{row.descriptor}'
            }}
    }
    
}
