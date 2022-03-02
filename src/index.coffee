
import './normalize.css'
import './index.css'

PHONE_RE = RegExp("^[+]?[0-9]{1,4}[-]?[0-9]{3}[-]?[0-9]{3}[-]?[0-9]{2}[-]?[0-9]{2}$")

arrayToObj = (arr) ->
  obj = {}
  obj[k] = v for [k,v] in arr
  obj

localStore = new Backbone.LocalStorage('UserStore')

User = Backbone.Model.extend(
  localStorage: localStore
  defaults:
    name: ''
    phone: ''
  validate: (attrs, options) ->
    reqErrs = ([ f, "Не зполнено поле: #{f}" ] for f in ['name', 'phone'] when not attrs[f])
    return reqErrs if reqErrs.length > 0
    return [[ 'phone', "Телефон указан некорректно" ]] unless PHONE_RE.test(attrs.phone)
)

UserList = Backbone.Collection.extend(
  model: User
  localStorage: localStore
  modelId: (attrs) ->
    attrs.id
)

RowView = Backbone.View.extend(
  initialize: ->
    @edit = false
    @model.on 'change', @render, this
    @model.on 'destroy', @remove, this
    return
  tagName: 'tr'
  template: _.template($('#item-template').html())
  render: (model = @model, err = {}) ->
    @$el.html(@template(_.extend({ edit: @edit, err }, model.attributes)))
    this
  events:
    'keypress .input': 'updateOnEnter'
    'click .cancel': 'close'
    'click .edit': 'edit'
    'click .save': 'save'
    'click .destroy': 'destroy'
  edit: ->
    @edit = true
    @render()
    inp = @el.querySelector('input')
    inp.focus() if inp
    return
  updateOnEnter: (e) ->
    if e.which == 13
      @save()
    return
  close: ->
    @edit = false
    @render()
    return
  save: ->
    [name, phone] = (@el.querySelector("[name=#{f}]").value for f in ["name", "phone"])
    tmpModel = new User
    tmpModel.set({ name, phone }, {silent: true })
    if tmpModel.isValid()
      @model.set(tmpModel.attributes)
      @model.save()
      @edit = false
      @render()
    else
      errs = tmpModel.validationError
      @render(tmpModel, arrayToObj(errs))
    return
  destroy: (event) ->
      @model.destroy()
)

AddRowView = Backbone.View.extend(
  initialize: ->
    @edit = false
    return
  el: '#add-row'
  template: _.template($('#addrow-template').html())
  render: (err = {}) ->
    @$el.html @template(_.extend({ edit: @edit, err }, @model.attributes))
    this
  events:
    'keypress .input': 'updateOnEnter'
    'click .add': 'edit'
    'click .save': 'save'
    'click .cancel': 'cancel'
  edit: ->
    @edit = true
    @render()
    inp = @el.querySelector('input')
    inp.focus() if inp
    return
  cancel: ->
    @edit = false
    @render()
    @model.set(@model.defaults, {silent: true })
    return
  updateOnEnter: (e) ->
    if e.which == 13
      @save()
    return
  save: ->
    [name, phone] = (@el.querySelector("[name=#{f}]").value for f in ["name", "phone"])
    @model.set({ name, phone }, {silent: true })
    if @model.isValid()
      @model.save()
      userList.add(@model)
      @model = new User
      @edit = false
      @render()
    else
      errs = @model.validationError
      @render(arrayToObj errs)
    return
)


AppView = Backbone.View.extend(
  el: '#app'
  initialize: ->
    @nodataTemplate = _.template($('#nodata-template').html())
    $('#add-row').append (new AddRowView(model: new User)).render().el
    userList.on 'add', @addOne, this
    userList.on 'remove', @removeOne, this
    userList.on 'sync', @checkEmpty, this   
    await userList.fetch()
  addOne: (model) ->
    parent = document.getElementById("user-list")
    nodataEl = document.querySelector(".nodata")
    if nodataEl
      parent.removeChild(nodataEl)
    view = new RowView(model: model)
    parent.appendChild view.render().el
  checkEmpty: ->
    if userList.length is 0
      $('#user-list').html @nodataTemplate()
      true
    else
      false
  removeOne: ->
    @checkEmpty()
  addAll: ->
    if not @checkEmpty()
      @addOne(u) for u in userList.models
      #usersHtml = ((new RowView(model: u)).render().el.innerHTML for u in userList.models)
      #$('#user-list').html usersHtml
)

userList = new UserList

Backbone.history.start()
appView = new AppView

# populate  localStore with some defaults
# localStore._clear()
if localStore.findAll().length is 0
  persons = []
  persons.push
    name: 'John Doe'
    phone: '189998885555'

  persons.push
    name: 'Super man'
    phone: '189995555555'

  persons.push
    name: 'Supergirl'
    phone: '15555555555'

  persons.push
    name: 'Spiderman'
    phone: '9999999999999'

  persons.push
    name: 'Gerrard Rene'
    phone: '189998885555'

  persons.forEach (p) ->
    m = new User(p)
    m.save({ silent: true })
    userList.add(m)
