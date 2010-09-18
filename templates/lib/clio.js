Clio = {
    dataURL: function(){return window.location.pathname.replace(/[^\/]+$/, '') + 'data/'},
        //return document.URL.replace(/[^\/]+$/, '') + 'data/'},

    indexesURL: function(){return Clio.dataURL() + 'indexes/';},
    entriesURL: function(){return Clio.dataURL() + 'entries/';},
    
    showMain: function(page){
        $.getJSON(Clio.indexesURL() + 'all.js', function(idx){
            row = idx.rows[0];
            Clio.showList(row.entries, page);
        });
        Clio.showSidebar();
    },
    
    showIndexEntry: function(index, trm, page){
        var term = Url.decode(trm.toString().replace('%C2%A0', '%20'))
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
            
            Clio.showList(row.entries, page)

            // если в имени индекса есть "|", то он и является вторичным индексом, который надо сейчас отобразить
            var subindex = index.indexOf('|') > -1 ? index : row.subindex 
            Clio.showSidebar(index, trm, subindex);
        });
        
    },
    
    showList: function(entry_ids, page){
        var pagesize = ClioSettings.pageSize;
        var p = page ? parseInt(page)-1 : 0
        var s = p*pagesize, e = (p+1)*pagesize;
        var entryIds = entry_ids.slice(s, e)
        var entries = [];
        $.each(entryIds, function(){
            $.getJSON(Clio.entriesURL() + this + '.js', function(entry){
                entries.push(entry);
                if(entries.length == entryIds.length){
                    $('#feed').render({entries: entries}, ClioTemplates.feed);
                }
            })
        });
        
        Clio.showPager(entry_ids.length, pagesize, p);
    },
    
    showEntry: function(eid){
        console.log(Clio.entriesURL() + eid + '.js')
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
                        var el = $('#sidebar a[href*=./list.html?index=' + indexdescr + '&term=' + term + ']')
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
                var el = $('#sidebar a[href*=./list.html?index=' + indexdescr + '&term=' + term + ']')
                el.attr('style', 'color:red');
            });
        }else{
            $('#sidebar #subindex').hide()
        }
    },
    
    showPager: function(count, pagesize, current){
        var pages = [];
        var baseUrl = document.URL.replace(/&?page=\d+$/, '')
        baseUrl += (baseUrl.indexOf('?') == -1) ? '?' : '&'
        for(var p = 0; p <= count/pagesize; p++){
            pages.push({title: (p + 1) + ' ', url: baseUrl + 'page=' + (p+1), 'class': (p == current ? 'current' : '')})
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
        Clio.showMain($.query.get('page'));
    }else if(document.URL.indexOf('list.html') != -1){

        Clio.showIndexEntry($.query.get('index'), $.query.get('term'), $.query.get('page'));
        
    }else if(document.URL.indexOf('entry.html') != -1){
        Clio.showEntry($.query.get('id'));
    }
    
    Clio.setupEvents()
});
