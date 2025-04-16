@props([
'url' => '/',
'icon' => null,
'bgClass' => 'bg-blue-500',
'hoverClass' => 'hover:bg-blue-600',
'textClass' => 'text-white',
'block' => false
])

<a href="{{$url}}"
    class="{{$bgClass}} {{$hoverClass}} {{$textClass}} px-4 py-2 rounded hover:shadow-md transition duration-300 {{$block ? 'block' : ''}}">
    @if($icon)
    <i class="fa fa-{{$icon}}"></i>
    @endif
    {{$slot}}
</a>
