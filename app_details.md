# TaskAway Mobile App - Project Summary

## Overview
TaskAway is a Malaysian-based task outsourcing platform that connects individuals who need help with various tasks (Posters) with those who can provide services (Taskers). The platform serves as a marketplace for a wide range of services, from odd jobs to heavy labor.

## Key Features

### For Posters (Task Requesters)
1. **Task Posting**
   - Create detailed task descriptions
   - Set budget and timeline
   - Receive and review offers from Taskers
   - Select the most suitable Tasker based on profiles, ratings, and reviews

2. **Task Management**
   - Track task progress
   - Communicate with Taskers
   - Release payment upon completion
   - Provide ratings and reviews

### For Taskers (Service Providers)
1. **Profile Management**
   - Create a detailed profile showcasing skills and experience
   - Set availability and service areas
   - Display ratings and reviews

2. **Task Browsing & Bidding**
   - Browse available tasks
   - Filter tasks by category, location, and budget
   - Submit competitive bids
   - Communicate with Posters

3. **Task Completion**
   - Mark tasks as completed
   - Receive payment
   - Earn ratings and reviews

## User Flows

### Poster Flow
1. Sign up/Login
2. Post a task with description and budget
3. Review offers from Taskers
4. Select preferred Tasker
5. Communicate and coordinate task details
6. Approve completed work
7. Release payment and provide feedback

### Tasker Flow
1. Sign up/Login
2. Complete profile with skills and experience
3. Browse available tasks
4. Submit bids for preferred tasks
5. Get hired by Posters
6. Complete tasks
7. Receive payment and ratings

## Technical Requirements

### Core Features
- User authentication (Posters & Taskers)
- Task creation and management
- Bid/Offer system
- In-app messaging
- Payment processing
- Rating and review system
- Push notifications
- Location-based services
- Image upload for task details

### User Roles
1. **Poster**
   - Create and manage tasks
   - Review and accept offers
   - Make payments
   - Rate Taskers

2. **Tasker**
   - Browse and bid on tasks
   - Manage accepted tasks
   - Receive payments
   - Build reputation

## UI/UX Considerations
- Clean, intuitive interface
- Mobile-first design
- Easy task posting process
- Clear task details and requirements
- Seamless communication between users
- Secure payment processing
- Rating and review system

## Business Model
- Commission-based revenue from completed tasks
- Potential premium features for Taskers (e.g., featured listings)
- Service fees for premium support or faster matching

## Technical Stack (Proposed)
- **Frontend**: Flutter (iOS & Android)
- **Backend**: Supabase
- **Authentication**: Supabase Auth
- **Database**: Supabase PostgreSQL
- **Real-time Updates**: Supabase Realtime
- **File Storage**: Supabase Storage
- **Payments**: Integration with local payment gateways
