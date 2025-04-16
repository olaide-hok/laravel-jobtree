@props(['url' => '/', 'active' => false, 'icon' => null, 'mobile' => false])

@if($mobile)
<a href="{{$url}}" class="block px-4 py-2 hover:bg-red-700 {{$active ? 'text-red-500 font-bold' : ''}}">
    @if($icon)
    <i class="fa fa-{{$icon}} mr-1"></i>
    @endif
    {{$slot}}
</a>
@else
<a href="{{$url}}" class="hover:text-red-500 hover:underline py-2 {{$active ? 'text-red-500 font-bold' : 'text-white'}}">
    @if($icon)
    <i class="fa fa-{{$icon}} mr-1"></i>
    @endif
    {{$slot}}
</a>
@endif
