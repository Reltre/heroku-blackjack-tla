$(document).ready(function() {
  $(document).on('click','#hit_form button',function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/hit',
    }).done(function(data) {
       $('#game').html(data);
    });


    return false;
  });
});


// index_start = data.indexOf('<div id="game">');
// index_finish = data.lastIndexOf('</div>');
// game_layout = data.substring(index_start,index_finish);


// success:function(data) {
// $('#game').html(data);
//       }   