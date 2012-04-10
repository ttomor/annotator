class Annotator.Plugin.Comment extends Annotator.Plugin
  events:
    'annotationViewerShown' : 'addReplyButton'
    '.annotator-save click': 'onReplyEntryClick'
    '.annotator-cancel click': 'hide'
    '.replyentry keydown' : 'processKeypress'
    '.replyentry click' : 'processKeypress'

  constructor: (element) ->
      super

    
  # Public: Initialises the plugin and adds custom fields to both the
  # annotator viewer and editor. The plugin also checks if the annotator is
  # supported by the current browser.
  #
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()
  
  # Add a reply button to the viewer widget's controls span
  addReplyButton: (viewer, annotations) ->
    # Annotations are displayed in the order they they were entered into the viewer
    
    # now look for annotations with the 'parent' field
    # and load them into
#   console.log(viewer)
#   reply_annotations = []
#   for ann in @annotator.dumpAnnotations()
#     if ann.parent
#       if ann.parent == annotation.id
#         reply_annotations.push ann
#   console.log('Reply annotations :', reply_annotations)

    annotator_listing = @annotator.element.find('.annotator-annotation.annotator-item')
    for l, i in annotator_listing
      l = $(l)
      
      replies = []
      # sort the annotations by creation time
      unsorted = @annotator.dumpAnnotations()
      sorted = unsorted.sort (a,b) ->
        return if a.created.toUpperCase() >= b.created.toUpperCase() then 1 else -1

      for ann in sorted.reverse()
        if ann.parent?
          if ann.parent == annotations[i].id
            replies.push ann.reply
      console.log(replies)
      if replies.length > 0
        l.append('''<div style='padding:5px'> <span> Replies </span></div>
            <div id="Replies">
          
          <li class="Replies">
          </li></div>''')
      if replies.length > 0
        replylist = @annotator.element.find('.Replies')
        
        # write the replies into the correct places of the viewer. This algorithm handles overlapping annotations 
        for reply in replies.reverse()
          $(replylist[i]).append('''<div class='reply'>
            <span class='replyuser'>''' + reply.user + '''</span><button class='annotator-delete-reply'>Delete</button>
            <div class='replytext'>''' + reply.reply + '''</div></div>''')

      # Add the textarea
      l.append('''<div class='replybox'>
          <textarea class="replyentry" placeholder="Reply to this annotation..."></textarea>
          ''')

    viewer.checkOrientation()

 
    
  # Handle the event when the submit button is clicked
  #
  onReplyEntryClick: (event) ->
    # get content of the textarea
    item =  $(event.target).parent().parent()
    textarea = item.find('.replyentry')
    reply = textarea.val()
    if reply != '' 
      replyObject = @getReplyObject()
      #console.log( @annotator.plugins.Permissions)
      if @annotator.plugins.Permissions.user 
        replyObject.user = @annotator.plugins.Permissions.user.name
      else
        replyObject.user = "Anonymous"

      replyObject.reply = reply

      item = $(event.target).parents('.annotator-annotation')
      
      annotation = item.data('annotation')  

      
      # make a new annotation object in which we can save the reply.
      @new_annotation = @annotator.createAnnotation()
      @new_annotation.ranges = [] 
      @new_annotation.parent = annotation.id
      
      replyObject = @getReplyObject()
      replyObject.user = @new_annotation.user
      replyObject.reply = reply
      @new_annotation.reply = replyObject
        

      # publish annotationUpdated event so that the store can save the changes
      this.publish('annotationUpdated', [annotation, @new_annotation])
      this.publish('annotationCreated', [@new_annotation])
      
      # hide the viewer
      @annotator.viewer.hide()
    
  showReplies: (event) ->
    console.log("show replies")
    # here we show the replies attached to the annotation
    viewer = @annotator.element.find('.annotator-annotation.annotator-item')
    replylist = viewer.find('.Replies')
    # get the annotation
    item = $(event.target).parents('.annotator-annotation')
    annotation = item.data('annotation')
     
    
    if replylist.length == 0
      viewer.append('''<div id="Replies">
        <li class="Replies">
        </li></div>''')
    replylist = viewer.find('.Replies')

    if replylist.children().length == 0
      # add all the replies into the div
      for reply in annotation.replies
        replylist.append('''<div class='reply'>
            <span class='replyuser'>''' + reply.user + '''</span>
            <div class='replytext'>''' + reply.reply + '''</div></div>''')





  getReplyObject: ->
    replyObject = 
        user: "anonymous"
        reply: ""
        
    replyObject
    
    
  processKeypress: (event) =>
    item =  $(event.target).parent()
    controls = item.find('.annotator-reply-controls')
    if controls.length == 0
      item.append('''<div class="annotator-reply-controls">
          <a href="#save" class="annotator-save">Save</a>
          <a href="#cancel" class="annotator-cancel">Cancel</a>
          </div>
          </div>
          ''')
      @annotator.viewer.checkOrientation()

    if event.keyCode is 27 # "Escape" key => abort.
      @annotator.viewer.hide()
    else if event.keyCode is 13 and !event.shiftKey
      # If "return" was pressed without the shift key, we're done.
      @onReplyEntryClick(event)
 
  hide: ->
    @annotator.viewer.hide()
