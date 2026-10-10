---
title: Domain Model
layout: aim42-page
permalink: /reference/domain-model/
lede: The entities aim42 considers during improvement, such as issues, causes and improvements, with their definitions and relationships.
---

Systematic improvement works with a few kinds of information, the **entities** of the aim42 domain model.
The diagram shows how they relate; select an entity to jump to its definition.
The [introduction](/reference/introduction/#common-terminology) tells the same story in a simpler picture.

{% include aim42/domain-model.html %}

{% for group in site.data.domain-model.groups %}
<h2 id="{{ group.id }}">{{ group.title }}</h2>

{{ group.intro }}

<dl class="domain-model-terms">
{%- for entity in group.entities %}
  <dt id="{{ entity.id }}">{{ entity.name }}</dt>
  <dd>
    <p>{{ entity.definition | markdownify | remove: "<p>" | remove: "</p>" | strip }}</p>
    {%- if entity.attributes or entity.relations %}
    <ul>
      {%- for attribute in entity.attributes %}
      <li>{{ attribute | markdownify | remove: "<p>" | remove: "</p>" | strip }}</li>
      {%- endfor %}
      {%- for relation in entity.relations %}
      <li>{{ entity.name }} {{ relation | markdownify | remove: "<p>" | remove: "</p>" | strip }}</li>
      {%- endfor %}
    </ul>
    {%- endif %}
  </dd>
{%- endfor %}
</dl>
{% endfor %}
