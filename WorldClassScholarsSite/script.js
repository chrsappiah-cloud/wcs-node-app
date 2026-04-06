document.addEventListener('DOMContentLoaded', function () {
  const heroButton = document.querySelector('.primary-button');
  if (!heroButton) {
    return;
  }

  heroButton.addEventListener('click', function (event) {
    event.preventDefault();
    const contactSection = document.querySelector('#contact');
    if (contactSection) {
      contactSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
});
