
$(document).ready(function(){



    $(".approval_role").hide()
    $("#role_div").click(function(){
     $(".approval_role").show()
    })
    $("#hide_role_div").click(function(){
     $(".approval_role").hide()
    })
    if (window.location.href.indexOf("level") > -1) {
      $(".approval_role").show()  
    }


$( ".list_tag" ).autocomplete({
      source: function( request, response ) {
    project = window.location.href.split('/')[4]
    va = $( ".list_tag" ).val()
    cat_id = $("#category_approval_configs_project_category_id option:selected").val();
    $.ajax({
        
    url: '/projects/' + project + '/approval_definitions/get_tags?project_id='+project+'&&category_id='+cat_id+'&&position=1',
    dataType: 'json',
    type: "GET",
    data: {query: va},
    
    success: function (data) {
                response($.map(data, function(v,i){
                    return v
                }));
            }
    });
    }
});

$( ".list_tag_2" ).autocomplete({
      source: function( request, response ) {
    project = window.location.href.split('/')[4]
    cat_id = $("#category_approval_configs_project_category_id option:selected").val();
    $.ajax({
        
    url: '/projects/' + project + '/approval_definitions/get_tags',
    dataType: 'json',
    type: "GET",
    data: {project_id: project, category_id: cat_id, position : 1 },
    
    success: function (data) {
                response($.map(data, function(v,i){
                    return v
                }));
            }
    });
    }
});




// Ticketing Approval response ----------------> START <---------------
    $('#approve_btn_tkt').click(function () {
        $('#tkt_response_area').show();
        $('#tkt_comment').attr('data-approve', 'true')
        $('#tkt_comment').attr('data-reject', 'false')
        $('#reject_btn_tkt').attr('disabled', true)
        $('#save_tkt').attr('disabled', false)
    })
    $('#reject_btn_tkt').click(function () {
        $('#tkt_response_area').show();
        $('#tkt_comment').attr('data-approve', 'false')
        $('#tkt_comment').attr('data-reject', 'true')
        $('#approve_btn_tkt').attr('disabled', true)

    })
    $('#cancel_tkt').click(function(){
        $('#tkt_cmt_error').css('color','black')
        $('#tkt_response_area, .counter_msg').hide();
        $('#tkt_comment').val('');
        $('#reject_btn_tkt').attr('disabled', false)
        $('#approve_btn_tkt').attr('disabled', false)
    });


    if ($( "#respond_msg p:visible" ).size() > 1){
        $('#tkt_get_respond').hide();
        $('#respond_msg').show();
    }
    else
    {
        $('#respond_msg').hide();
        $('#tkt_get_respond').show();

    }

    $("#save_tkt").unbind().click(function() {
        status = $('#tkt_comment').attr('data-approve')
        role = $('#approve_btn_tkt').attr('data-role')
        if (($.trim($('#tkt_comment').val()).length < 1) && status == 'false'){
            $('#tkt_cmt_error').css('color','red');
            return false;
        }
        p_id = $('#response_btn').attr('data-project_id')
        $.ajax({
            url: "/projects/"+ $('#approve_btn_tkt').attr('data-project_id') +"/approval_definitions/respond_ticket",
            type: 'get',
            data: {project_id: p_id, issue_id: $('#approve_btn_tkt').attr('data-issue_id'), comment: $('#tkt_comment').val(), status: status, role: role },
            success: function (data) {
              if (data.result){
                  $('#tkt_get_respond').hide();
                  console.log('-------- res-----')
                  console.log(data.result)
                  window.location.href = "/projects/"+ $('#approve_btn_tkt').attr('data-project_id') +"/issues";
              }else{
                $('#tkt_cmt_error').html("<div 'style=width:100%'><span style='float:left' >Please enter comment.</span><span style='float:right;margin-right:5%;color:red' >Approval workflow is missing, Please contact your manager.</span></div>");
                return false;
              }
            }
        });
    });

    $('#tkt_get_respond').on('focus keypress', '#tkt_comment', function (e) {
        $('.tkt_counter_msg').show();
        $('#save_tkt').attr('disabled', false)
        var $this = $(this);
        var msgSpan = $this.parents('#get_respond').find('.tkt_counter_msg');
        var ml = parseInt($this.attr('maxlength'), 10);
        var length = $.trim(this.value).length;
        var msg = ml - length + ' characters of ' + ml + ' characters left';
        msgSpan.html(msg);
    });


// Ticketing Approval response ----------------> END <---------------


  $('#tkt_form_btn,#tkt_form_btn1').click(function(){
    if ($('#normal_flow label:eq(1)').text() == 'Description for request*'){
      if ($.trim($('#issue_description').val()) == '') {
        $('#errorExplanation').show().html("<ul><li>Please enter Description for request.</li></ul> ")
        return false;
      }
       else{
        $('#errorExplanation').hide()
        txt = $('.suggest_tkt a span').text()
         $('<input>').attr({ type: 'hidden', name: 'ticket[task_name]', value: txt  }).appendTo('#issue-form');
        return true;
      }
    }

  })



    if ( $("#category_approval_configs_project_category_id").is(":visible") ) {
        s = document.getElementById("category_approval_configs_project_category_id");
        category = s.options[s.selectedIndex].text
        id = s.options[s.selectedIndex].value
        check_cat_value(id)
    };



    $('#add_values').click(function(){
        count = $(".tk_app_val input[type='text']").length +1
        name1 = 'category_approval_configs[values][]'
        $('.tk_app_val div').append( $( "<input name="+name1+" size='30' placeholder='Value"+count +"'  type='text' class='list_tag_"+count+"'>" ) );
        if (count == 5){
            $('#add_values').hide()
        }

    });

    // $('#add_level').click(function(){
    //     count = $(".tk_app_form_tbl input[type='checkbox']").length
    //     name1 = 'category_approval_configs[levels][]'
    //     $('.tk_app_form_tbl thead tr ').append( $( "<th>A"+ count +"</th>" ) );
    //     $('#last_level').before( $( "<td><input name="+ name1 +" type='checkbox' value='1'></td>" ) );
    //     if (count == 8){
    //         $('#add_level').hide()
    //     }
    // });


    $('#category_approval_configs_project_category_id').bind( "change load", function( event ) {
        console.log('asaS');
            e = document.getElementById("category_approval_configs_project_category_id");
        category = e.options[e.selectedIndex].text
        id = e.options[e.selectedIndex].value
        check_cat_value(id)
    });

    $("#category_approval_configs_project_category_id").change(function() {
        id = $('option:selected', this).val()
        setTicketingNonTicketing(id)
    });

    $('#cat_select').change(function() {
        id = $('option:selected', this).val()
        $.ajax({
            url: '/projects/'+ window.location.href.split('/')[4] +'/ticketing_project_categories/' + id +'',
            type: 'get',
            success: function(result) {
                if (result.need_approval){
                    $('#ticketing_flow #tkt_cat').show();
                    $('#request_for').show();
                    $('#issue_sub').hide();
                    $('#frm_sub').attr('name', '')
                    $(".new_issue input[value='Create']").attr('id','tkt_form_btn')
                    $('#normal_flow label:eq(1)').text('Description for request').append("<span style='margin-left:5px;color:red'>*</span>")
                }else{

                  console.log('----- max--- val-----')
                    $('#request_for').hide();
                    $('#issue_sub').show();
                    $('#frm_sub').attr('name', 'issue[subject]');
                    $('#s2id_tkt_frm_sub').hide()
                    $('#normal_flow label:eq(1)').text('Description')
                }
            }
        });
    });



    $('#delete_cat').click(function(){
        d = document.getElementById("category_approval_configs_project_category_id");
        category = d.options[d.selectedIndex].text
        id = d.options[d.selectedIndex].value
        if (confirm("Are you sure you want to delete the <b>"+ category +"</b> Category")) {
            $.ajax({
                url: '/projects/'+ window.location.href.split('/')[4] +'/ticketing_project_categories/' + id +'',
                type: 'DELETE',
                success: function(result) {
                    console.log('-------------')
                    if (result.file_content=='fails'){
                        $('#flash_notice').hide()
                        $('#errorExplanation').show().html("<ul><li>Sorry!, <b>"+ category +"</b> Category was associate with some records.</li></ul> ")
                    }else if (result.file_content=='okay'){
                        $('#errorExplanation').hide()
                        $('#flash_notice').show().html("<ul><li> <b>"+ category +"</b> was successfully deleted.</li></ul> ")
                        d.options.remove(d.selectedIndex)
                    }
                }
            });
        }
    });

    $('#request_for #tkt_frm_sub').click(function(){
        if ($('#ticketing_project_id').val() == '' && $('#cat_select').val() == ''){
            $('.tkt_err').show()
            $('.tkt_err ul li').html('<li>Please Select Project and Category.</li>');
            return false;
        }else if ($('#ticketing_project_id').val() == ''){
            $('.tkt_err').show()
            $('.tkt_err ul li').html('<li>Please Select Project.</li>');
            return false
        }else if ($('#cat_select').val() == ''){
            $('.tkt_err').show()
            $('.tkt_err ul li').html('<li>Please Select Category.</li>');
            return false
        }
        else {
            $('.tkt_err').hide()

        }
    });

    $('#cat_select').change(function(){
        cat = document.getElementById("cat_select");
        id = cat.options[cat.selectedIndex].value;
        if ($('#ticketing_project_id').val() == ''){
            $('.tkt_err').show()
            $('.tkt_err ul li').html('<li>Please Select Project.</li>');
            $("#cat_select option:selected").attr("selected", false);
        }else{
            $('.tkt_err').hide()
            $(".suggest_tkt").select2({
                minimumInputLength: 2,
                placeholder: "Select a ticket",
                allowClear: true,
                ajax: {
                    url: '/projects/' + window.location.href.split('/')[4] + '/approval_definitions/associate_tickets?category_id=' + id,
                    dataType: 'json',
                    type: "GET",
                    quietMillis: 50,
                    data: function (term) {
                        return {
                            term: term
                        };
                    },
                    results: function (data) {
                        var myResults = [];
                        $.each(data.result, function (index, item) {
                            myResults.push({
                                'id': item.id,
                                'text': item.text
                            });
                        });
                        return {
                            results: myResults
                        };
                    }
                }
            });
        }
    })

    // onload trigger ticketing option
    if ($('.new_issue #issue_tracker_id').is(":visible")){
        updatetrackerFrom("/projects/"+ window.location.href.split('/')[4] +"/approval_definitions/set_tracker.js ")
    }
 // multiple interruption

  $(document).on('click', ".interrupt_ico", function() {

//    console.log($(this).attr('data_interrupt'));
    approval = $(this).attr('data_interrupt');
    role_id = $(this).attr('data_interrupt_role_id');
    $('#category_approval_configs_'+approval)
    if ($('#category_approval_configs_'+approval).prop('checked')==true) {

      $('#ajax-modal').html(" <div class='box '><div id='interruption_content'> </div>" +
        " <table><tr id='interruption_type'><th >Type of Interruption <span class='required'>*</span> </th><td> <input type='radio' name='type' value='override'><label for='override'>Override</label><input type='radio' name='type' value='intermediate'><label for='override'>Intermediate</label></td></tr>" +
        "<tr><th> </th><td><input type='hidden' id='inter_level' value=" + approval + "> </td></tr>   " + "<tr><th> </th><td><input type='hidden' id='inter_level_role' value=" + role_id + "> </td></tr>   " +
        "<tr><th>User To Approve  <span class='required'>*</span></th><td>   <select id='user_select'></select></td></tr>" +
        "<tr><th></th><td> <button type='button' value='Submit' class='save_interrupt'>Save</button> <button type='reset' class='cancel_interrupt' value='Reset'>Cancel</button></td></tr></table>" +
        "</div>");


      $.ajax({url: " /approval_definitions/group_users", success: function (result) {
        $.each(result.users, function (index, item) { // Iterates through a collection
          $("#user_select").append( // Append an object to the inside of the select box
            $("<option></option>").text(item[1]).val(item[0]));
        });
      }});
      showModal('ajax-modal', '450px');
      setTimeout(function () {
        if ($('.' + approval).length != 0) {
          $('#ajax-modal').append("<button type='button' value='Submit' id='remove_interrupt'>Remove</button>")
          checked = $("input[name='interruption[type][]'][class=" + approval + "]").val()
          console.log('checked-------')
          
          select_value = $("input[name='interruption[user][]'][class=" + approval + "]").val()
          $(":radio[value=" + checked + "]").attr('checked', true);
          console.log(checked, approval, select_value)
          $("#user_select option[value=" + select_value + "]").attr("selected", "selected");
        }
      }, 500);
    }else{
      alert('please select the '+ approval)
    }
  });

  $(document).on('click', "#interruption_type", function() {
    approval = $('#inter_level').val()    
    if ($("input:radio[name='type']:checked").val() == 'override'){
      $('#interruption_content').html("<b>Your going to Override "+ approval +"</b>")
    }else if ($("input:radio[name='type']:checked").val() == 'intermediate'){
      $('#interruption_content').html("<b>Your going to add Intermediate approval before "+ approval +"</b>")
    }
    $('#interruption_content').html()
  })

  $(document).on('click', ".cancel_interrupt", function() {
    hideModal();
  });

  $(document).on('click', "#remove_interrupt", function() {
    approval = $('#inter_level').val()
    role_id = $('#inter_level_role').val()
    id = $("#user_select option:selected").val()
    params =[ approval, id,role_id ]
    $('.'+approval).remove()
    $('<input>').attr({ type: 'hidden', class: approval, name: 'interruption[delete][position][]', value: approval  }).appendTo('.tk_ap_form form');
    $('<input>').attr({ type: 'hidden', class: approval, name: 'interruption[delete][user][]', value: id  }).appendTo('.tk_ap_form form');
    $('<input>').attr({ type: 'hidden', class: approval, name: 'interruption[delete][role][]', value: role_id  }).appendTo('.tk_ap_form form');
    hideModal();
    $("*[data_interrupt="+ approval +"]").removeClass('interrupt_grid');
  });


  $(document).on('click', ".save_interrupt", function() {
    override = $("input:radio[name='type']:checked").val()
    approval = $('#inter_level').val()
    id = $("#user_select option:selected").val()
    role_id = $('#inter_level_role').val()
    params =[ approval, override, id ]
    $('.'+approval).remove()
    $('<input>').attr({ type: 'hidden', class: approval, name: 'interruption[type][]', value: override  }).appendTo('.tk_ap_form form');
    $('<input>').attr({ type: 'hidden', class: approval, name: 'interruption[position][]', value: approval  }).appendTo('.tk_ap_form form');
    $('<input>').attr({ type: 'hidden', class: approval, name: 'interruption[user][]', value: id  }).appendTo('.tk_ap_form form');
    $('<input>').attr({ type: 'hidden', class: approval, name: 'interruption[role][]', value: role_id  }).appendTo('.tk_ap_form form');
    hideModal();
    $("*[data_interrupt="+ approval +"]").addClass('interrupt_grid');
  });

  if ($("td.tk_app_val").is(":visible")) {
    var data_ticket = $('td.tk_app_val').attr('data_ticket');
    if (data_ticket != '') {
      $.ajax({url: " /approval_definitions/update_interruption?ticket=" + data_ticket, success: function (result) {
        $.each(result.data, function (index, item) {
            
          $("*[data_interrupt=" + item[0] + "]").addClass('interrupt_grid');
          $('<input>').attr({ type: 'hidden', class: item[0], name: 'interruption[type][]', value: item[1]  }).appendTo('.tk_ap_form form');
          $('<input>').attr({ type: 'hidden', class: item[0], name: 'interruption[position][]', value: item[0]  }).appendTo('.tk_ap_form form');
          $('<input>').attr({ type: 'hidden', class: item[0], name: 'interruption[user][]', value: item[2] }).appendTo('.tk_ap_form form');
          $('<input>').attr({ type: 'hidden', class: item[0], name: 'interruption[role][]', value: item[3]  }).appendTo('.tk_ap_form form');
        });
      }});
    }
  }

});





function setTicketingNonTicketing(id){
    console.log('================ max')
    $.ajax({
        url: '/projects/'+ window.location.href.split('/')[4] +'/ticketing_project_categories/' + id +'',
        type: 'get',
        success: function(result) {
            if (result.need_approval){
                $('.approval').show();
            }else{
                $('.approval').hide();
            }
        }
    });

}

function updatetrackerFrom(url) {
    console.log('----------max=========')
    $('#all_attributes input, #all_attributes textarea, #all_attributes select').each(function(){
        $(this).data('valuebeforeupdate', $(this).val());
    });
    $.ajax({
        url: url,
        type: 'post',
        data: $('#issue-form').serialize(),
        success: function(result) {
            if (result.project == true){
                $('#ticketing_flow p:first').show()
            }else{
                $('#ticketing_flow p:first').hide()
            }
            if (result.approval == true){
                $('#ticketing_flow #tkt_cat').show();
                $('#request_for').show();
                $('#issue_sub').hide();
                $('#frm_sub').attr('name', '')
                $(".new_issue input[value='Create']").attr('id','tkt_form_btn')
                $('#normal_flow label:eq(1)').text('Description for request').append("<span style='margin-left:5px;color:red'>*</span>")
            }else{
                $('#request_for').hide();
                $('#issue_sub').show();
              $('#frm_sub').attr('name', 'issue[subject]');
                $('#ticketing_flow #tkt_cat, #s2id_tkt_frm_sub').hide()
                $('#normal_flow label:eq(1)').text('Description')
            }
        }
    });
}


function check_cat_value(id){
    if (id > 0) {
        $('.app_cat_action').show()
    } else {
        $('.app_cat_action').hide()
    }
}



