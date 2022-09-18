module AdminHelper
  def link_to_pretty_user(user, include_id_fragment = true)
    txs = user.name.to_s
    txs += " (#{user.id.to_s.truncate(8, omission: '')})" if include_id_fragment
    link_to txs, admin_user_path(user)
  end

  def link_to_pretty_character(character, include_verified_icon = true, include_id_fragment = false)
    link_text = character.character_name.to_s
    link_text += " (#{character.id.to_s.truncate(8, omission: '')})" if include_id_fragment
    link = link_to link_text, admin_character_path(character)

    link += verified_mark(character.verified?, title: 'Verified Character') if include_verified_icon

    link.html_safe
  end

  def pretty_character_name(character, include_verified_icon = true, include_id_fragment = false)
    txs = character.character_name.to_s
    txs += " (#{character.id.to_s.truncate(8, omission: '')})" if include_id_fragment
    txs += verified_mark(character.verified?, title: 'Verified Character') if include_verified_icon

    txs.html_safe
  end
end
