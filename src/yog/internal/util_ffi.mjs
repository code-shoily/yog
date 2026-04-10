import { toList } from "../../gleam.mjs";

/**
 * Creates an array from a Gleam list.
 * @template T
 * @param {List<T>} list - Gleam list
 * @returns {Array<T>} JavaScript array
 */
export function arrayFromList(list) {
  return [...list];
}

/**
 * Converts a JavaScript array to a Gleam list.
 * @template T
 * @param {Array<T>} arr - JavaScript array
 * @param {number} _size - Size hint (unused, for API compatibility)
 * @returns {List<T>} Gleam list
 */
export function arrayToList(arr, _size) {
  return toList(arr);
}

/**
 * Gets an element at the specified index.
 * @template T
 * @param {Array<T>} arr - JavaScript array
 * @param {number} index - Index (0-based)
 * @returns {T} Element at index
 */
export function arrayGet(arr, index) {
  return arr[index];
}

/**
 * Sets an element at the specified index, returning a new array.
 * Note: This mutates the array for performance, but the shuffle
 * algorithm only modifies each position once in a controlled way.
 * @template T
 * @param {Array<T>} arr - JavaScript array
 * @param {number} index - Index (0-based)
 * @param {T} value - Value to set
 * @returns {Array<T>} The same array (mutated)
 */
export function arraySet(arr, index, value) {
  arr[index] = value;
  return arr;
}
