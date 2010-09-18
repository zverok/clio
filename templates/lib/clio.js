Clio = {
    dataURL: function(){return window.location.pathname.replace(/[^\/]+$/, '') + 'data/'},
        //return document.URL.replace(/[^\/]+$/, '') + 'data/'},

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
    
    showList: function(index, trm, page){
        var term = Url.decode(trm.replace('%C2%A0', '%20'))
        $.getJSON(Clio.indexesURL() + index + '.js', function(idx){
            var row;
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

            var shortTitle = idx.meta.title + ': ' + row.title
            $('title').text(shortTitle)
            $('.home .title a').text(shortTitle)

            var pagesize = ClioSettings.pageSize;
            var p = page ? parseInt(page)-1 : 0
            var s = p*pagesize, e = (p+1)*pagesize;
            var entryIds = row.entries.slice(s, e)
            var entries = [];
            $.each(entryIds, function(){
                $.getJSON(Clio.entriesURL() + this + '.js', function(entry){
                    entries.push(entry);
                    if(entries.length == entryIds.length){
                        $('#feed').render({entries: entries}, ClioTemplates.feed);
                    }
                })
            });
            
            Clio.showPager(row.entries.length, pagesize, p);
            
            // если в имени индекса есть "|", то он и является вторичным индексом, который надо сейчас отобразить
            var subindex = index.indexOf('|') > -1 ? index : row.subindex 
            Clio.showSidebar(index, trm, subindex);
        });
        
    },
    
    showEntry: function(eid){
        $.getJSON(Clio.entriesURL() + eid + '.js', function(entry){
            $('title').text(entry.body.replace(/<a.+?<\/a>/, '').substring(0, 50) + '...')
            
            $('div.body').render(entry, ClioTemplates.entry);
        });
        
        Clio.showSidebar();
    },
    
    showSidebar: function(indexdescr, term, subindex){
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
        
        if(subindex){
            $.getJSON(Clio.indexesURL() + subindex + '.js', function(index){
                $('#sidebar #subindex').show()
                $('#sidebar #subindex').render({index: index}, ClioTemplates.sidebarSubindex);

                //на случай, если выбранный термин относится ко вторичному индексу
                var el = $('#sidebar a[href*=./list.html#' + indexdescr + ':' + term + ']')
                el.attr('style', 'color:red');
            });
        }else{
            $('#sidebar #subindex').hide()
        }
    },
    
    showPager: function(count, pagesize, current){
        var pages = [];
        var baseUrl = document.URL.replace(/\/\d+$/, '')
        for(var p = 0; p <= count/pagesize; p++){
            pages.push({title: (p + 1) + ' ', url: baseUrl + '/' + (p+1), 'class': (p == current ? 'current' : '')})
        }
        $('.pager').render({pages: pages}, ClioTemplates.pager);
        if(count <= pagesize)
            $('.pager').hide()
        else
            $('.pager').show()
    },
    
    setupEvents: function(){
        //sidebar
        $('#sidebar .group-title').live('click', function(){
            $('.group-contents').hide();
            $(this).parents('.group').find('.group-contents').show()
            return false;
        });
        
        $('#sidebar .sidebar-nav').live('click', function(){
            if(window.location.pathname.indexOf('list.html') != -1){
                window.location.hash = $(this).attr('href').match(/\#.+/)[0];
                window.location.reload()
                return false;
            }else{
                return true;
            }
        });
    }
    
}

$(document).ready(function(){
    if(document.URL.indexOf('index.html') != -1){
        Clio.showIndex();
    }else if(document.URL.indexOf('list.html') != -1){
        var index_term = document.URL.split('#', 2)[1].split(':', 2);
        var index = index_term[0], term = index_term[1];
        var page;
        if(term.indexOf('/') != -1){
            var term_page = term.split('/')
            term = term_page[0]; page = term_page[1]
        }
        Clio.showList(index, term, page);
        
    }else if(document.URL.indexOf('entry.html') != -1){
        var eid = document.URL.split('#', 2)[1];
        Clio.showEntry(eid);
    }
    
    Clio.setupEvents()
});
