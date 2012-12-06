Clio = {
    dataURL: function(){return window.location.pathname.replace(/[^\/]+$/, '') + 'data/'},

    indexesURL: function(){return Clio.dataURL() + 'indexes/';},
    entriesURL: function(){return Clio.dataURL() + 'entries/';},
    
    showMain: function(page){
        $.getJSON(Clio.indexesURL() + 'all.js', function(idx){
            row = idx.rows[0];
            Clio.showList(row.entries, page);
        });
        Clio.showSidebar();
        Clio.setupEvents();
    },
    
    showIndexEntry: function(index, trm, page){
        var term = trm.toString(); 
        var trm = Url.encode(trm.toString()).replace(/\%20/g, '+');
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

            // если в имени индекса есть "__", то он и является вторичным индексом, который надо сейчас отобразить
            var subindex = index.indexOf('__') > -1 ? index : row.subindex 
            Clio.showSidebar(index, trm, subindex);

            Clio.setupEvents()
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
                if(entry.comments && entry.comments.length > 3){
                    entry.firstComments = [entry.comments[0]]
                    entry.lastComments = [entry.comments[entry.comments.length-1]]
                    entry.hiddenComments = entry.comments.slice(1, entry.comments.length-1)
                    delete(entry.comments)
                }
                entries.push(entry);
                if(entries.length == entryIds.length){
                    $('#feed').render({entries: entries}, ClioTemplates.feed);
                    $('.middle_comments').each(function(){
                        if($(this).find('.comment').length > 0){
                            $(this).find('.hidden_comments_stub').text($(this).find('.comment').length.toString() + ' more comments')
                        }
                    })
                }
            })
        });
        
        Clio.showPager(entry_ids.length, pagesize, p);
    },
    
    showEntry: function(eid){
        $.getJSON(Clio.entriesURL() + eid + '.js', function(entry){
            $('title').text(entry.body.replace(/<a.+?<\/a>/, '').substring(0, 50) + '...')
            
            $('div.entry').render(entry, ClioTemplates.entry);
        });
        
        Clio.showSidebar();
        Clio.setupEvents();
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
                        el.addClass('clio-current')
                        el.parents('.group').addClass('clio-expanded');
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
                el.addClass('clio-current');
            });
        }else{
            $('#sidebar #subindex').hide()
        }
    },
    
    showPager: function(count, pagesize, current){
        var pages = [];
        var last_page = (count-1)/pagesize;
        var baseUrl = document.URL.replace(/[\?&]page=\d+$/, '')
        baseUrl += (baseUrl.indexOf('?') == -1) ? '?' : '&'
        for(var p = 0; p <= last_page; p++){
            pages.push({title: (p + 1) + ' ', url: baseUrl + 'page=' + (p+1), 'class': (p == current ? 'clio-current' : '')})
        }
        $('.pager').render({pages: pages}, ClioTemplates.pager);
        if(count <= pagesize)
            $('.pager').hide()
        else
            $('.pager').show()
    },
    
    setupEvents: function(){
        //show/hide comments
        $('.hidden_comments_stub').live('click', function(){
            $(this).parents('.middle_comments').addClass('clio-show-comments').removeClass('expandcomment')
            return false;
        });
        //sidebar
        $('#sidebar .group-title').live('click', function(){
            $('.group').removeClass('clio-expanded');
            $(this).parents('.group').addClass('clio-expanded');
            return false;
        });
    }
    
}
