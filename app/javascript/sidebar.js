/*
 * Sidebar Toggle Functionality
 * Replaces Hope UI sidebar JavaScript with vanilla Bootstrap approach
 * Compatible with Turbo/Hotwire navigation
 */

"use strict";

// Initialize sidebar functionality
function initializeSidebar() {
  const sidebar = document.querySelector('.sidebar');
  const sidebarBackdrop = document.querySelector('.sidebar-backdrop');
  const toggleButtons = document.querySelectorAll('[data-toggle="sidebar"]');

  if (!sidebar) return;

  // Remove existing listeners by cloning buttons (prevents duplicate listeners)
  toggleButtons.forEach(button => {
    const newButton = button.cloneNode(true);
    button.parentNode.replaceChild(newButton, button);
  });

  // Re-query after cloning
  const freshToggleButtons = document.querySelectorAll('[data-toggle="sidebar"]');

  // Toggle sidebar on button click
  freshToggleButtons.forEach(button => {
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
    const newBackdrop = sidebarBackdrop.cloneNode(true);
    sidebarBackdrop.parentNode.replaceChild(newBackdrop, sidebarBackdrop);

    newBackdrop.addEventListener('click', () => {
      sidebar.classList.remove('show');
      newBackdrop.classList.remove('show');
    });
  }

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
}

// Initialize Bootstrap components
function initializeBootstrapComponents() {
  // Initialize tooltips
  if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
    const tooltipTriggerList = [].slice.call(
      document.querySelectorAll('[data-bs-toggle="tooltip"]')
    );
    tooltipTriggerList.map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
  }

  // Initialize popovers
  if (typeof bootstrap !== 'undefined' && bootstrap.Popover) {
    const popoverTriggerList = [].slice.call(
      document.querySelectorAll('[data-bs-toggle="popover"]')
    );
    popoverTriggerList.map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl));
  }
}

// Run on initial page load
document.addEventListener('DOMContentLoaded', () => {
  initializeSidebar();
  initializeBootstrapComponents();
});

// Run on Turbo navigation (page transitions)
document.addEventListener('turbo:load', () => {
  initializeSidebar();
  initializeBootstrapComponents();
});

// Run after Turbo morph (when page morphs instead of replaces)
document.addEventListener('turbo:morph', () => {
  initializeSidebar();
  initializeBootstrapComponents();
});

// Handle window resize (only set up once)
let resizeTimeout;
window.addEventListener('resize', () => {
  clearTimeout(resizeTimeout);
  resizeTimeout = setTimeout(() => {
    const sidebar = document.querySelector('.sidebar');
    const sidebarBackdrop = document.querySelector('.sidebar-backdrop');

    if (!sidebar) return;

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
