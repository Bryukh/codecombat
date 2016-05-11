RootView = require 'views/core/RootView'
Classrooms = require 'collections/Classrooms'
State = require 'models/State'
Prepaids = require 'collections/Prepaids'
template = require 'templates/courses/enrollments-view'
Users = require 'collections/Users'
Courses = require 'collections/Courses'

module.exports = class EnrollmentsView extends RootView
  id: 'enrollments-view'
  template: template

  events:
    'input #students-input': 'onInputStudentsInput'

  initialize: (options) ->
    me.set('role', 'teacher') # TODO: Remove later
    
    @state = new State({
      totalEnrolled: 0
      totalNotEnrolled: 0
      classroomNotEnrolledMap: {}
      classroomEnrolledMap: {}
      numberOfStudents: 15
    })

    @ownedClassrooms = new Classrooms()
    @supermodel.trackRequest @ownedClassrooms.fetchMine({data: {project: '_id'}})
    
    @courses = new Courses()
    @supermodel.trackRequest @courses.fetch({data: { project: 'free' }})
    @members = new Users()
    @classrooms = new Classrooms()
    @classrooms.comparator = '_id'
    @listenToOnce @classrooms, 'sync', @onceClassroomsSync
    @supermodel.trackRequest @classrooms.fetch({data: {ownerID: me.id}})
    @prepaids = new Prepaids()
    @prepaids.comparator = '_id'
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id)

  onceClassroomsSync: ->
    for classroom in @classrooms.models
      @supermodel.trackRequests @members.fetchForClassroom(classroom, {remove: false, removeDeleted: true})

  onLoaded: ->
    @calculateEnrollmentStats()
    super()

  calculateEnrollmentStats: ->
    @removeDeletedStudents()
    @memberEnrolledMap = {}
    for user in @members.models
      @memberEnrolledMap[user.id] = user.get('coursePrepaidID')?
      
    @state.set('totalEnrolled', _.reduce @members.models, ((sum, user) ->
      sum + (if user.get('coursePrepaidID') then 1 else 0)
    ), 0)
    
    @state.set('totalNotEnrolled', _.reduce @members.models, ((sum, user) ->
      sum + (if not user.get('coursePrepaidID') then 1 else 0)
    ), 0)
    
    @state.set('classroomEnrolledMap', _.reduce @classrooms.models, ((map, classroom) =>
      enrolled = _.reduce classroom.get('members'), ((sum, userID) =>
        sum + (if @members.get(userID).get('coursePrepaidID') then 1 else 0)
      ), 0
      map[classroom.id] = enrolled
      map
    ), {})
    
    @state.set('classroomNotEnrolledMap', _.reduce @classrooms.models, ((map, classroom) =>
      enrolled = _.reduce classroom.get('members'), ((sum, userID) =>
        sum + (if not @members.get(userID).get('coursePrepaidID') then 1 else 0)
      ), 0
      map[classroom.id] = enrolled
      map
    ), {})
    
    true
    
  removeDeletedStudents: (e) ->
    for classroom in @classrooms.models
      _.remove(classroom.get('members'), (memberID) =>
        not @members.get(memberID) or @members.get(memberID)?.get('deleted')
      )
    true

  onInputStudentsInput: ->
    input = @$('#students-input').val()
    if input isnt "" and (parseFloat(input) isnt parseInt(input) or _.isNaN parseInt(input))
      @$('#students-input').val(@state.get('numberOfStudents'))
    else
      @state.set('numberOfStudent', Math.max(parseInt(@$('#students-input').val()) or 0, 0))

  numberOfStudentsIsValid: -> 0 < @get('numberOfStudents') < 100000
  
  # onClickEnrollStudents: ->
  # TODO: Needs "All students" in modal dropdown
