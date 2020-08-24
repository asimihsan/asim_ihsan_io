(function() {
    // ------------------------------------------------------------------------
    //  Nav-burger click.
    // ------------------------------------------------------------------------

    // Get all "navbar-burger" elements
    const $navbarBurgers = Array.prototype.slice.call(document.querySelectorAll('.navbar-burger'), 0);
  
    // Check if there are any navbar burgers
    if ($navbarBurgers.length > 0) {
  
      // Add a click event on each of them
      $navbarBurgers.forEach( el => {
        el.addEventListener('click', () => {
  
          // Get the target from the "data-target" attribute
          const target = el.dataset.target;
          const $target = document.getElementById(target);
  
          // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
          el.classList.toggle('is-active');
          $target.classList.toggle('is-active');
  
        });
      });
    }
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    //  Contact form.
    // ------------------------------------------------------------------------
    {{ if eq (getenv "HUGO_ENV") "production" | or (eq .Site.Params.env "production")  }}
    const contactEndpoint = "https://contact.ihsan.io";
    {{ else }}
    const contactEndpoint = "https://preprod-contact.ihsan.io";
    {{ end }}

    const $contactForm = document.getElementById("contact-form");
    $contactForm.onsubmit = async (e) => {
      e.preventDefault();
      disableSubmitButton();
      const data = {};
      for (let i = 0; i < $contactForm.elements.length; i++) {
        const element = $contactForm.elements[i];
        if (element.name === "") {
          continue;
        }
        data[element.name] = element.value;
      }
      const body = JSON.stringify(data);
      console.log(body);
      let response = await fetch(contactEndpoint + '/api/post_contact_form', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: body
      });
      let result = await response.json();
      enableSubmitButton();
      console.log(result);
      if (result.success) {
        showContactFormSuccess();
      } else {
        showContactFormFailure();
      }
    };

    document.getElementById("contact-submit-button").disabled = true;
    document.getElementById("contact-form-status").style.visibility = "collapse";
    document.getElementById("contact-form-success").style.visibility = "collapse";
    document.getElementById("contact-form-failure").style.visibility = "collapse";
    // ------------------------------------------------------------------------
})();

function disableSubmitButton() {
  document.getElementById("contact-submit-button").disabled = true;
}

function enableSubmitButton() {
  document.getElementById("contact-submit-button").disabled = false;
}

function showContactFormSuccess() {
  document.getElementById("contact-form-status").style.visibility = "visible";
  document.getElementById("contact-form-success").style.visibility = "visible";
  document.getElementById("contact-form-failure").style.visibility = "collapse";
}

function showContactFormFailure() {
  document.getElementById("contact-form-status").style.visibility = "visible";
  document.getElementById("contact-form-success").style.visibility = "collapse";
  document.getElementById("contact-form-failure").style.visibility = "visible";
}