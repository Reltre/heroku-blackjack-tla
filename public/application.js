function updateDealerHand() {
  $.ajax({
    type: 'POST',
    url: '/game/dealer-hit'
        }).done(function(data){
          updateDisplay(data)
          setTimeout(checkDealerTotal(),7000);
        });       
}

function checkDealerTotal() {
  $.get('/game/stats').done(function(data) {
    if (parseInt(data) < 17) {
      updateDealerHand();
    }
  });
}

function updateDisplay(data) {
   $('#game').replaceWith(data);
}

$(document).ready(function() {
  $(document).on('click','#hit_form button',function() {
    $.ajax({
      type: 'POST',
      url: '/game/player-hit'
    }).done(function(data) {
       $('#game').replaceWith(data);
    });

    return false;
  });

  $(document).on('click','#stay_form button',function() {
     $.get('/game_state').done(function(data) {
       $('#game').replaceWith(data);
     }).done(function() {
      checkDealerTotal();
    });
     
    return false; 
  });  
});
