$(document).ready(function() {

  $(document).on('click', '#hit_form input', function() {
    $.ajax( {  // these are the parameters, on diff lines as per JS style
      type: 'POST',
      url: '/hit'
    }).done(function(msg) {
        $('#game').replaceWith(msg);
      });

    return false; // so that the form is not submitted (it has been hijacked)
  });

  $(document).on('click', '#stay_form input', function() {
    $.ajax( {
      type: 'POST',
      url: '/stay'
    }).done(function(msg) {
        $('#game').replaceWith(msg);
      });

    return false;
  });

  $(document).ready(function() {
    $(document).on('click', '#next_card_form input', function() {
      $.ajax( {
        type: 'POST',
        url: '/next_dealer_card'
      }).done(function(msg) {
          $('#game').replaceWith(msg);
        });
      return false;
    });
  });

});
