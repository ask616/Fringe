$(document).ready(function(){
	var myRef = new Firebase("https://blue-outsidehacks.firebaseio.com/");
	var auth = new FirebaseSimpleLogin(myRef, function(error, user) {
	  if (error) {
	    // an error occurred while attempting login
	    console.log(error);
	  } else if (user) {
	     if( true ) {
	      // save new user's profile into Firebase so we can
	      // list users, use them in security rules, and show profiles
	      myRef.child('users').child(user.uid).set({
	        displayName: user.displayName,
	        data:user.thirdPartyUserData
	      });
    	}
	  } else {
	    // user is logged out
	  }
	});

	$('#fb-login').click(function(){
	auth.login('facebook', {
	  rememberMe: true,
	  scope: 'email,user_friends'
	});
});

})