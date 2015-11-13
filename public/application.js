
$(document).ready(function() {
  playerHit();
  playerStay();
});

function updateDealerHand() {
  $.ajax({
    type: 'POST',
    url: '/game/dealer-hit'
        }).done(function(data){
          setTimeout(function() {updateDisplay(data);},3000);
          checkDealerTotal();
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

function playerHit() {
  $(document).on('click','#hit_form button',function() {
    $.post('/game/player-hit').done(function(data) {
        updateDisplay(data);
    });

    return false;
  });

}

function playerStay() {
  $(document).on('click','#stay_form button',function() {
     $.get('/game_state').done(function(data) {
        updateDisplay(data);
     }).done(function() {
      checkDealerTotal();
    });

    return false;
  });
}
