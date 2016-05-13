RootView = require 'views/core/RootView'
Classrooms = require 'collections/Classrooms'
State = require 'models/State'
Prepaids = require 'collections/Prepaids'
template = require 'templates/courses/enrollments-view'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
HowToEnrollModal = require 'views/teachers/HowToEnrollModal'
TeachersContactModal = require 'views/teachers/TeachersContactModal'

module.exports = class EnrollmentsView extends RootView
  id: 'enrollments-view'
  template: template

  events:
    'input #students-input': 'onInputStudentsInput'
    'click #how-to-enroll-link': 'onClickHowToEnrollLink'
    'click #contact-us-btn': 'onClickContactUsButton'

  initialize: ->
    @state = new State({
      totalEnrolled: 0
      totalNotEnrolled: 0
      classroomNotEnrolledMap: {}
      classroomEnrolledMap: {}
      numberOfStudents: 15
      totalCourses: 0
      prepaidGroups: {
        'available': []
        'pending': []
      }
    })

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
    @state.set('totalCourses', @courses.size())
    @state.set('prepaidGroups', @prepaids.groupBy((p) -> p.status()))
    super()

  calculateEnrollmentStats: ->
    @removeDeletedStudents()
    @memberEnrolledMap = {}
    for user in @members.models
      @memberEnrolledMap[user.id] = user.get('coursePrepaidID')?
      
    @state.set('totalEnrolled', _.reduce @members.models, ((sum, user) ->
      sum + (if user.get('coursePrepaidID') then 1 else 0)
    ), 0)
    
    totalNotEnrolled = _.reduce @members.models, ((sum, user) ->
      sum + (if not user.get('coursePrepaidID') then 1 else 0)
    ), 0
    @state.set('totalNotEnrolled', totalNotEnrolled)
    @state.set('numberOfStudents', totalNotEnrolled)
    
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

  onClickHowToEnrollLink: ->
    @openModalView(new HowToEnrollModal())

  onClickContactUsButton: ->
    @openModalView(new TeachersContactModal({ enrollmentsNeeded: @state.get('numberOfStudents') }))
    
  onInputStudentsInput: ->
    input = @$('#students-input').val()
    if input isnt "" and (parseFloat(input) isnt parseInt(input) or _.isNaN parseInt(input))
      @$('#students-input').val(@state.get('numberOfStudents'))
    else
      @state.set('numberOfStudents', Math.max(parseInt(@$('#students-input').val()) or 0, 0))

  numberOfStudentsIsValid: -> 0 < @get('numberOfStudents') < 100000
  
  # onClickEnrollStudents: ->
  # TODO: Needs "All students" in modal dropdown
