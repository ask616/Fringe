$(document).ready(function(){
	var myRef = new Firebase("https://blue-outsidehacks.firebaseio.com/");
	var auth = new FirebaseSimpleLogin(myRef, function(error, user) {
	  if (error) {
	    // an error occurred while attempting login
	    console.log(error);
	  } else if (user) {

	      // save new user's profile into Firebase so we can
	      // list users, use them in security rules, and show profiles
	      myRef.child('users').child(user.displayName).update({
	        data:user.thirdPartyUserData
	      });

	  } else {
	    // user is logged out
	  }
	});

	var authRef = new Firebase("https://blue-outsidehacks.firebaseio.com/.info/authenticated");
		authRef.on("value", function(snap) {
		  if (snap.val() === true) {
		    console.log("authenticated");
		    window.location.replace("http://getblue.herokuapp.com/map");
		  } else {
		    console.log("not authenticated");
		  }
		});

	// $('#fb-login').click(function(){
	// auth.login('facebook', {
	//   rememberMe: true,
	//   scope: 'user_friends'
	// });
});

})