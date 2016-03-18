#include <time.h>
#include <iostream>



int main()
{
	time_t now=time(0);
	std::cerr<<ctime(&now);
	std::cout<<now<<std::endl;
	return 0;
}