EnrollmentsView = require 'views/courses/EnrollmentsView'
Courses = require 'collections/Courses'
factories = require 'test/app/factories'

describe 'EnrollmentsView', ->
  
  beforeEach (done) ->
    me.set('anonymous', false)
    me.set('role', 'teacher')
    @view = new EnrollmentsView()
    @view.classrooms.fakeRequests[0].respondWith({ status: 200, responseText: '[]' })
    @view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: '[]' })
    courses = new Courses([
      factories.makeCourse({free: true})
      factories.makeCourse({free: false})
      factories.makeCourse({free: false})
      factories.makeCourse({free: false})
    ])
    @view.courses.fakeRequests[0].respondWith({ status: 200, responseText: courses.stringify() })
    jasmine.demoEl(@view.$el)
    window.view = @view
    @view.supermodel.once 'loaded-all', done

  it 'shows how many courses there are which enrolled students will have access to', ->
    expect(_.contains(@view.$('#enrollments-blurb').text(), '2–4')).toBe(true)
