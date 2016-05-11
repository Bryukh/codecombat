EnrollmentsView = require 'views/courses/EnrollmentsView'
Courses = require 'collections/Courses'
factories = require 'test/app/factories'

describe 'EnrollmentsView', ->
  
  beforeEach (done) ->
    view = new EnrollmentsView()
    view.ownedClassrooms.fakeRequests[0].respondWith({ status: 200, responseText: '[]' })
    view.classrooms.fakeRequests[0].respondWith({ status: 200, responseText: '[]' })
    view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: '[]' })
    courses = new Courses([
      factories.makeCourse({free: true})
      factories.makeCourse({free: false})
      factories.makeCourse({free: false})
    ])
    view.courses.fakeRequests[0].respondWith({ status: 200, responseText: courses.stringify() })
    jasmine.demoEl(view.$el)
    window.view = view
    view.supermodel.once('all-loaded', done)
    
  it 'shows up', ->
    console.log 'yep'
