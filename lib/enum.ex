defmodule Enum do
  defprotocol Iterator, [iterator(collection)], only: [List]
  require Enum::Iterator, as: I

  # Invokes the given `fun` for each item in the `collection`
  # checking if the result of the function invocation evalutes
  # to true. If any does not, abort.
  #
  # ## Examples
  #
  #     Enum.all? [2,4,6], fn(x) { rem(x, 2) == 0 }
  #     #=> true
  #
  #     Enum.all? [2,3,4], fn(x) { rem(x, 2) == 0 }
  #     #=> false
  #
  # If no function is given, it defaults to checking if
  # all items in the collection evalutes to true.
  #
  #     Enum.all? [1,2,3]   #=> true
  #     Enum.all? [1,nil,3] #=> false
  #
  def all?(collection, fun // fn(x) { x }) do
    _all?(I.iterator(collection).(), fun)
  end

  # Invokes the given `fun` for each item in the `collection`.
  # Returns the `collection` itself.
  #
  # ## Examples
  #
  #     Enum.each ['some', 'example'], fn(x) { IO.puts x }
  #
  def each(collection, fun) do
    _each(I.iterator(collection).(), fun)
    collection
  end

  # Iterates the collection from left to right passing an
  # accumulator as parameter. Returns the accumulator.
  #
  # ## Examples
  #
  #     Enum.foldl [1, 2, 3], 0, fn(x, acc) { x + acc }
  #     #=> 6
  #
  def foldl(collection, acc, f) do
    _foldl(I.iterator(collection).(), acc, f)
  end

  # Join the given `collection` according to `joiner`.
  # Joiner can be either a binary or a list and the
  # result will be of the same type of joiner.
  #
  # ## Examples
  #
  #     Enum.join([1,2,3], " = ") #=> "1 = 2 = 3"
  #     Enum.join([1,2,3], ' = ') #=> '1 = 2 = 3'
  #
  def join(collection, joiner) when is_list(joiner) do
    binary_to_list join(collection, list_to_binary(joiner))
  end

  def join(collection, joiner) do
    _join(I.iterator(collection).(), joiner, nil)
  end

  # Invokes the given `fun` for each item in the `collection`.
  # Returns the result of all function calls.
  #
  # ## Examples
  #
  #     Enum.map [1, 2, 3], fn(x) { x * 2 }
  #     #=> [2, 4, 6]
  #
  def map(collection, fun) do
    _map(I.iterator(collection).(), fun)
  end

  # Invokes the given `fun` for each item in the `collection`
  # while also keeping an accumulator. Returns a tuple where
  # the first element is the iterated collection and the second
  # one is the final accumulator.
  #
  # ## Examples
  #
  #     Enum.mapfoldl [1, 2, 3], 0, fn(x, acc) { { x * 2, x + acc } }
  #     #=> { [2, 4, 6], 6 }
  #
  def mapfoldl(collection, acc, fun) do
    _mapfoldl(I.iterator(collection).(), acc, fun)
  end

  ## Implementations

  def _all?({ h, next }, fun) do
    case fun.(h) do
    match: false
      false
    match: nil
      false
    else:
      _all?(next.(), fun)
    end
  end

  def _all?(__STOP_ITERATOR__, _) do
    true
  end

  ## each

  defp _each({ h, next }, fun) do
    fun.(h)
    _each(next.(), fun)
  end

  defp _each(__STOP_ITERATOR__, _fun) do
    []
  end

  ## foldl

  defp _foldl({ h, next }, acc, f) do
    _foldl(next.(), f.(h, acc), f)
  end

  defp _foldl(__STOP_ITERATOR__, acc, _f) do
    acc
  end

  ## join

  # The first item is simply stringified unless ...
  defp _join({ h, next }, joiner, nil) do
    _join(next.(), joiner, stringify(h))
  end

  # The first item is __STOP_ITERATOR__, then we return an empty string;
  defp _join(__STOP_ITERATOR__, _joiner, nil) do
    ""
  end

  # All other items are concatenated to acc, by first adding the joiner;
  defp _join({ h, next }, joiner, acc) do
    acc = << acc | :binary, joiner | :binary, stringify(h) | :binary >>
    _join(next.(), joiner, acc)
  end

  # Until we have to stop iteration, then we return acc.
  defp _join(__STOP_ITERATOR__, _joiner, acc) do
    acc
  end

  ## map

  defp _map({ h, next }, fun) do
    [fun.(h)|_map(next.(), fun)]
  end

  defp _map(__STOP_ITERATOR__, _fun) do
    []
  end

  ## mapfoldl

  defp _mapfoldl({ h, next }, acc, f) do
    { result, acc } = f.(h, acc)
    { rest, acc }   = _mapfoldl(next.(), acc, f)
    { [result|rest], acc }
  end

  defp _mapfoldl(__STOP_ITERATOR__, acc, _f) do
    { [], acc }
  end
end

defimpl Enum::Iterator, for: List do
  def iterator(list) do
    fn { iterate(list) }
  end

  defp iterate([h|t]) do
    { h, fn { iterate(t) } }
  end

  defp iterate([]) do
    __STOP_ITERATOR__
  end
end