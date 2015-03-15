$(document).ready(function(){
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
})
