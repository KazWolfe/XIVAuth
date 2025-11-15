/*
 * Sidebar Toggle Functionality
 * Replaces Hope UI sidebar JavaScript with vanilla Bootstrap approach
 */

"use strict";

// Sidebar toggle functionality
document.addEventListener('DOMContentLoaded', () => {
  const sidebar = document.querySelector('.sidebar');
  const sidebarBackdrop = document.querySelector('.sidebar-backdrop');
  const toggleButtons = document.querySelectorAll('[data-toggle="sidebar"]');

  if (!sidebar) return;

  // Toggle sidebar on button click
  toggleButtons.forEach(button => {
    button.addEventListener('click', (e) => {
      e.preventDefault();

      // On desktop (>= 1200px), toggle mini mode
      if (window.innerWidth >= 1200) {
        sidebar.classList.toggle('sidebar-mini');
      } else {
        // On mobile, toggle show/hide
        sidebar.classList.toggle('show');
        if (sidebarBackdrop) {
          sidebarBackdrop.classList.toggle('show');
        }
      }
    });
  });

  // Close sidebar when clicking backdrop
  if (sidebarBackdrop) {
    sidebarBackdrop.addEventListener('click', () => {
      sidebar.classList.remove('show');
      sidebarBackdrop.classList.remove('show');
    });
  }

  // Handle window resize
  let resizeTimeout;
  window.addEventListener('resize', () => {
    clearTimeout(resizeTimeout);
    resizeTimeout = setTimeout(() => {
      if (window.innerWidth >= 1200) {
        // On desktop, remove mobile classes
        sidebar.classList.remove('show');
        if (sidebarBackdrop) {
          sidebarBackdrop.classList.remove('show');
        }
      } else {
        // On mobile, remove mini class
        sidebar.classList.remove('sidebar-mini');
      }
    }, 250);
  });

  // Activate submenu items that contain the active link
  const activeLinks = sidebar.querySelectorAll('.nav-link.active');
  activeLinks.forEach(link => {
    const parentCollapse = link.closest('.collapse');
    if (parentCollapse) {
      // Show the parent collapse
      parentCollapse.classList.add('show');

      // Find and update the parent link
      const parentLink = sidebar.querySelector(`[href="#${parentCollapse.id}"]`);
      if (parentLink) {
        parentLink.classList.remove('collapsed');
        parentLink.setAttribute('aria-expanded', 'true');
      }
    }
  });
});

// Initialize Bootstrap tooltips
document.addEventListener('DOMContentLoaded', () => {
  if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
    const tooltipTriggerList = [].slice.call(
      document.querySelectorAll('[data-bs-toggle="tooltip"]')
    );
    tooltipTriggerList.map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
  }
});

// Initialize Bootstrap popovers
document.addEventListener('DOMContentLoaded', () => {
  if (typeof bootstrap !== 'undefined' && bootstrap.Popover) {
    const popoverTriggerList = [].slice.call(
      document.querySelectorAll('[data-bs-toggle="popover"]')
    );
    popoverTriggerList.map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl));
  }
});
