# Project Blueprint

## Overview

This document outlines the blueprint of the West Valley Gardens Flutter application. The purpose of this application is to serve as a central hub for the West Valley Gardens community, providing information about events, meetings, and other relevant resources. The app aims to enhance community engagement and provide a seamless user experience for students, faculty, and community members.

## Implemented Features & Design

### Core Functionality

*   **Home Page:** Displays a welcome message and links to the official website and Instagram page.
*   **Events Page:** A comprehensive event management system with a calendar view.
    *   Users can view events by day, week, or month.
    *   Add new events with details like title, description, location, and time.
    *   RSVP to events using their ASUrite ID.
    *   Upload and display event flyers.
*   **Meetings Page:** Provides information about weekly student leadership meetings and monthly faculty/staff meetings, including Zoom links and access to previous meeting recordings.
*   **Navigation:** A persistent bottom navigation bar for easy access to all main sections of the app.

### Design & Theming

*   **Color Scheme:** A green-themed color palette that aligns with the garden's branding.
*   **Typography:** Clear and readable fonts for all text elements.
*   **Layout:** Consistent and intuitive layouts across all pages.

### New `Problem` Feature

*   **Report a Problem:** A new feature that allows users to report any issues or problems they encounter within the app or the garden.
    *   A "Report a Problem" button is available on the app's main pages.
    *   Clicking the button opens a dialog with a text field for describing the problem.
    *   Upon submission, a "Thank you" confirmation is displayed.
*   **Problems List Page:** A dedicated page to display a list of all reported problems.
    *   The list is retrieved from the Firestore database.
    *   Each problem in the list shows the description and the date it was reported.