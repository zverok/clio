Clio = {
    dataURL: function(){return document.URL.replace(/[^\/]+$/, '') + 'data/'},

    indexesURL: function(){return Clio.dataURL() + 'indexes/';},
    entriesURL: function(){return Clio.dataURL() + 'entries/';},
    
    hashtagsURL: function(){return Clio.indexesURL() + 'hashtags.js';},

    showIndex: function(){
        $.getJSON(Clio.hashtagsURL(), function(data){
            $('ul').render({hashtags: data.rows}, {
                li: {'hashtag<-hashtags':{
                    'a': 'hashtag.title', 
                    'a@href+': 'hashtag.descriptor'
                }}
            })
        });
    },
    
    showList: function(index, trm){
        var term = Url.decode(trm.replace('%C2%A0', '%20'))
        $.getJSON(Clio.indexesURL() + index + '.js', function(idx){
            var row;
            console.log(trm)
            
            if(idx.meta.kind == 'grouped')
                $.each(idx.groups, function(){
                    $.each(this.rows, function(){
                        if(this['descriptor'] == trm) row = this;
                    })
                })
            else
                $.each(idx.rows, function(){
                    if(this['descriptor'] == trm) row = this;
                });
                
            var entries = [];
            $.each(row.entries, function(){
                $.getJSON(Clio.entriesURL() + this + '.js', function(entry){
                    entries.push(entry);
                    if(entries.length == row.entries.length){
                        $('#feed').render({entries: entries}, ClioTemplates.feed);
                    }
                })
            });
        });
        
        Clio.fillSidebar(index, trm);
    },
    
    showEntry: function(eid){
        $.getJSON(Clio.entriesURL() + eid + '.js', function(entry){
            $('title').text(entry.body)
            
            $('div.body').render(entry, ClioTemplates.entry);
        });
        
        Clio.fillSidebar();
    },
    
    fillSidebar: function(indexdescr, term){
        var indexids = ['dates', 'hashtags']
        var plain_indexes = [], grouped_indexes = [];
        
        $.each(indexids, function(){
            $.getJSON(Clio.indexesURL() + this + '.js', function(index){
                index.meta.kind == 'plain' ? plain_indexes.push(index) : grouped_indexes.push(index);
                
                if(plain_indexes.length + grouped_indexes.length == indexids.length){
                    $('#sidebar #grouped-indexes').render({indexes: grouped_indexes}, ClioTemplates.sidebarGroupedIndexes);

                    $('#sidebar #plain-indexes').render({indexes: plain_indexes}, ClioTemplates.sidebarPlainIndexes);
                    
                    if(indexdescr && term){
                        var el = $('#sidebar a[href*=./list.html#' + indexdescr + ':' + term + ']')
                        el.attr('style', 'color:red');
                        el.parents('.group-contents').show();
                    }
                }
            });
        });
    },
    
    setupEvents: function(){
        //sidebar
        $('#sidebar .group-title').live('click', function(){
            $('.group-contents').hide();
            $(this).parents('.group').find('.group-contents').show()
            return false;
        });
        
        $('#sidebar .sidebar-nav').live('click', function(){
            window.location.hash = $(this).attr('href').match(/\#.+/)[0];
            window.location.reload()
            return false;
        });
    }
    
}

$(document).ready(function(){
    if(document.URL.indexOf('index.html') != -1){
        Clio.showIndex();
    }else if(document.URL.indexOf('list.html') != -1){
        var index_term = document.URL.split('#', 2)[1].split(':', 2);
        var index = index_term[0], term = index_term[1];
        Clio.showList(index, term);
    }else if(document.URL.indexOf('entry.html') != -1){
        var eid = document.URL.split('#', 2)[1];
        Clio.showEntry(eid);
    }
    
    Clio.setupEvents()
});
