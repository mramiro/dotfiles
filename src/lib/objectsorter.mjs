/* 
 * Silly little helper functions to sort objects
 */

export default class ObjectSorter {

  sortArrayByProperty(input, propertyName) {
    input.sort((a, b) => (a[propertyName] > b[propertyName]) ? 1: -1);
  }
  
  sortObjectKeys(unsorted) {
    const sorted = {};
    Object.keys(unsorted).sort().forEach((key) => {
      sorted[key] = unsorted[key];
    });
    return sorted;
  }
}
